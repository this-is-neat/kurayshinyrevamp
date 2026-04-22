using SharpCompress.Archives;
using SharpCompress.Archives.SevenZip;
using SharpCompress.Readers;
using System.Runtime.InteropServices;

namespace InstallerBootstrap;

internal static class InstallerEngine
{
    private const string ArchiveRootPrefix = "PIF/";
    private const string DesktopShortcutName = "Kuray Infinite Fusion.lnk";
    private const string StartMenuFolderName = "Kuray Infinite Fusion";
    private const string CompatibilityShortcutName = "Kuray Infinite Fusion Compatibility Mode.lnk";
    private const int ManagedExtractProgressStepBytes = 16 * 1024 * 1024;

    public static void Install(
        InstallerOptions options,
        IProgress<InstallProgress>? progress,
        CancellationToken cancellationToken)
    {
        var installRoot = Path.GetFullPath(options.TargetDirectory);
        InstallWorkspace.CleanupStaleStageDirectories(installRoot);

        foreach (var package in ReleasePayloadManifest.GetPackagesForInstall(installRoot, options.UpdateOnly))
        {
            cancellationToken.ThrowIfCancellationRequested();
            InstallPackage(package, installRoot, progress, cancellationToken);
        }

        EnsureWritableDirectories(installRoot);

        if (!options.SkipShortcuts)
        {
            progress?.Report(new InstallProgress("Creating shortcuts...", string.Empty, 100, 100));
            CreateShortcuts(installRoot);
        }

        progress?.Report(new InstallProgress("Installation complete.", installRoot, 100, 100));
    }

    private static void InstallPackage(
        PayloadPackageManifest package,
        string installRoot,
        IProgress<InstallProgress>? progress,
        CancellationToken cancellationToken)
    {
        using var workspace = new InstallWorkspace(installRoot);
        workspace.Prepare();
        using var source = PayloadLocator.OpenPayloadSource(package, progress, cancellationToken);

        if (BundledSevenZip.CanUseFastExtraction(source, installRoot))
        {
            BundledSevenZip.ExtractArchiveToStageRoot(source.ArchiveFilePath!, workspace.StagingRoot, progress, cancellationToken);
            EnsureWritableDirectories(workspace.ExtractedRoot);
            DeployStagedInstall(workspace, progress, package);
            return;
        }

        using var payloadStream = source.CreatePayloadStream();
        using var archive = SevenZipArchive.OpenArchive(payloadStream, new ReaderOptions());

        var entries = archive.Entries
            .Where(entry => !entry.IsDirectory)
            .ToList();

        if (entries.Count == 0)
        {
            throw new InvalidOperationException($"The payload for '{package.DisplayName}' does not contain any files.");
        }

        long totalBytes = entries.Sum(entry => entry.Size);
        long extractedBytes = 0;
        long nextProgressBytes = ManagedExtractProgressStepBytes;
        progress?.Report(new InstallProgress("Preparing files...", package.DisplayName, 0, totalBytes));

        foreach (var entry in entries)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var relativePath = NormalizeEntryPath(entry.Key);
            if (string.IsNullOrEmpty(relativePath))
            {
                extractedBytes += entry.Size;
                continue;
            }

            var destinationPath = GetSafeDestinationPath(workspace.ExtractedRoot, relativePath);
            var destinationDirectory = Path.GetDirectoryName(destinationPath);
            if (!string.IsNullOrEmpty(destinationDirectory))
            {
                Directory.CreateDirectory(destinationDirectory);
            }

            progress?.Report(new InstallProgress("Extracting files...", relativePath, extractedBytes, totalBytes));

            using var entryStream = entry.OpenEntryStream();
            using var outputStream = new FileStream(
                destinationPath,
                FileMode.Create,
                FileAccess.Write,
                FileShare.None,
                bufferSize: 1024 * 1024,
                options: FileOptions.SequentialScan);
            var buffer = new byte[1024 * 1024];
            int bytesRead;
            while ((bytesRead = entryStream.Read(buffer, 0, buffer.Length)) > 0)
            {
                cancellationToken.ThrowIfCancellationRequested();
                outputStream.Write(buffer, 0, bytesRead);
                extractedBytes += bytesRead;
                if (extractedBytes >= nextProgressBytes || extractedBytes == totalBytes)
                {
                    progress?.Report(new InstallProgress("Extracting files...", relativePath, extractedBytes, totalBytes));
                    nextProgressBytes = extractedBytes + ManagedExtractProgressStepBytes;
                }
            }

            File.SetLastWriteTime(destinationPath, entry.LastModifiedTime ?? DateTime.Now);
        }

        EnsureWritableDirectories(workspace.ExtractedRoot);
        DeployStagedInstall(workspace, progress, package);
    }

    private static string NormalizeEntryPath(string? key)
    {
        if (string.IsNullOrWhiteSpace(key))
        {
            return string.Empty;
        }

        var normalized = key.Replace('\\', '/');
        if (normalized.StartsWith(ArchiveRootPrefix, StringComparison.OrdinalIgnoreCase))
        {
            normalized = normalized.Substring(ArchiveRootPrefix.Length);
        }

        return normalized.TrimStart('/');
    }

    private static string GetSafeDestinationPath(string installRoot, string relativePath)
    {
        var fullPath = Path.GetFullPath(Path.Combine(installRoot, relativePath));
        var fullRoot = Path.GetFullPath(installRoot);

        if (!fullPath.StartsWith(fullRoot + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(fullPath, fullRoot, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException($"Unsafe archive path detected: {relativePath}");
        }

        return fullPath;
    }

    private static void EnsureWritableDirectories(string installRoot)
    {
        foreach (var relativePath in new[] { "Cache", "ExportedPokemons", "Logs" })
        {
            Directory.CreateDirectory(Path.Combine(installRoot, relativePath));
        }
    }

    private static void DeployStagedInstall(
        InstallWorkspace workspace,
        IProgress<InstallProgress>? progress,
        PayloadPackageManifest package)
    {
        progress?.Report(new InstallProgress("Finalizing installation...", package.DisplayName, 100, 100));
        DeployStagedInstall(workspace.ExtractedRoot, workspace.InstallRoot);
    }

    private static void DeployStagedInstall(string stagedRoot, string installRoot)
    {
        if (!Directory.Exists(stagedRoot))
        {
            throw new InvalidOperationException("The installer staging folder is missing.");
        }

        if (IsDirectoryEmptyOrMissing(installRoot))
        {
            if (Directory.Exists(installRoot))
            {
                Directory.Delete(installRoot);
            }

            Directory.Move(stagedRoot, installRoot);
            return;
        }

        CopyDirectoryContents(stagedRoot, installRoot);
        InstallerCleanup.TryDeleteDirectory(stagedRoot);
    }

    private static void CopyDirectoryContents(string sourceRoot, string destinationRoot)
    {
        foreach (var sourceDirectory in Directory.EnumerateDirectories(sourceRoot, "*", SearchOption.AllDirectories))
        {
            var relativePath = Path.GetRelativePath(sourceRoot, sourceDirectory);
            Directory.CreateDirectory(GetSafeDestinationPath(destinationRoot, relativePath));
        }

        foreach (var sourceFile in Directory.EnumerateFiles(sourceRoot, "*", SearchOption.AllDirectories))
        {
            var relativePath = Path.GetRelativePath(sourceRoot, sourceFile);
            var destinationPath = GetSafeDestinationPath(destinationRoot, relativePath);
            var destinationDirectory = Path.GetDirectoryName(destinationPath);
            if (!string.IsNullOrEmpty(destinationDirectory))
            {
                Directory.CreateDirectory(destinationDirectory);
            }

            File.Copy(sourceFile, destinationPath, overwrite: true);
            File.SetLastWriteTime(destinationPath, File.GetLastWriteTime(sourceFile));
        }
    }

    private static bool IsDirectoryEmptyOrMissing(string path)
    {
        return !Directory.Exists(path) || !Directory.EnumerateFileSystemEntries(path).Any();
    }

    private static void CreateShortcuts(string installRoot)
    {
        var gamePath = Path.Combine(installRoot, "Game.exe");
        var compatibilityPath = Path.Combine(installRoot, "Game-compatibility.exe");

        CreateShortcut(
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), DesktopShortcutName),
            gamePath,
            installRoot,
            gamePath);

        var startMenuFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), StartMenuFolderName);
        Directory.CreateDirectory(startMenuFolder);

        CreateShortcut(
            Path.Combine(startMenuFolder, "Kuray Infinite Fusion.lnk"),
            gamePath,
            installRoot,
            gamePath);

        if (File.Exists(compatibilityPath))
        {
            CreateShortcut(
                Path.Combine(startMenuFolder, CompatibilityShortcutName),
                compatibilityPath,
                installRoot,
                compatibilityPath);
        }
    }

    private static void CreateShortcut(string shortcutPath, string targetPath, string workingDirectory, string iconPath)
    {
        var shellType = Type.GetTypeFromProgID("WScript.Shell")
            ?? throw new InvalidOperationException("Unable to access WScript.Shell for shortcut creation.");
        dynamic shell = Activator.CreateInstance(shellType)
            ?? throw new InvalidOperationException("Unable to create WScript.Shell instance.");

        try
        {
            dynamic shortcut = shell.CreateShortcut(shortcutPath);
            shortcut.TargetPath = targetPath;
            shortcut.WorkingDirectory = workingDirectory;
            shortcut.IconLocation = iconPath + ",0";
            shortcut.Save();
        }
        finally
        {
            if (Marshal.IsComObject(shell))
            {
                Marshal.FinalReleaseComObject(shell);
            }
        }
    }
}

internal readonly record struct InstallProgress(string Phase, string Detail, long ExtractedBytes, long TotalBytes);
