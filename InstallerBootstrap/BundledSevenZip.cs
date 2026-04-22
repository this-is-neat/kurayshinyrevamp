using System.Diagnostics;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;

namespace InstallerBootstrap;

internal static class BundledSevenZip
{
    private const string ToolVersion = "2026-04-22";
    private const string ResourceExeName = "InstallerBootstrap.NativeTools.7z.exe";
    private const string ResourceDllName = "InstallerBootstrap.NativeTools.7z.dll";

    public static bool CanUseFastExtraction(PayloadSource source, string installRoot)
    {
        return !string.IsNullOrWhiteSpace(source.ArchiveFilePath);
    }

    public static void ExtractArchiveToStageRoot(
        string archivePath,
        string stageRoot,
        IProgress<InstallProgress>? progress,
        CancellationToken cancellationToken)
    {
        var sevenZipExePath = EnsureTooling();
        Directory.CreateDirectory(stageRoot);
        progress?.Report(new InstallProgress("Extracting files...", "Preparing fast extraction...", 0, 100));
        RunSevenZipExtraction(sevenZipExePath, archivePath, stageRoot, progress, cancellationToken);

        var extractedRoot = Path.Combine(stageRoot, "PIF");
        if (!Directory.Exists(extractedRoot))
        {
            throw new InvalidOperationException("The extracted archive did not produce the expected PIF folder.");
        }
    }

    private static string EnsureTooling()
    {
        var toolsRoot = Path.Combine(Path.GetTempPath(), "KurayInfiniteFusionInstaller", "tools", ToolVersion);
        Directory.CreateDirectory(toolsRoot);

        var exePath = Path.Combine(toolsRoot, "7z.exe");
        var dllPath = Path.Combine(toolsRoot, "7z.dll");

        ExtractResourceIfMissing(ResourceExeName, exePath);
        ExtractResourceIfMissing(ResourceDllName, dllPath);

        return exePath;
    }

    private static void ExtractResourceIfMissing(string resourceName, string outputPath)
    {
        if (File.Exists(outputPath))
        {
            return;
        }

        using var resourceStream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException($"Bundled installer tool is missing: {resourceName}");
        using var outputStream = new FileStream(outputPath, FileMode.Create, FileAccess.Write, FileShare.None);
        resourceStream.CopyTo(outputStream);
    }

    private static void RunSevenZipExtraction(
        string sevenZipExePath,
        string archivePath,
        string outputDirectory,
        IProgress<InstallProgress>? progress,
        CancellationToken cancellationToken)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = sevenZipExePath,
            Arguments = $"x \"{archivePath}\" -o\"{outputDirectory}\" -y -mmt=on -bb0 -bd -bso0 -bsp1 -bse0",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        using var process = new Process
        {
            StartInfo = startInfo
        };

        process.Start();

        using var cancellationRegistration = cancellationToken.Register(() =>
        {
            try
            {
                if (!process.HasExited)
                {
                    process.Kill(entireProcessTree: true);
                }
            }
            catch
            {
            }
        });

        var progressTask = Task.Run(() => PumpProgress(process.StandardOutput, progress, cancellationToken), cancellationToken);
        var errorTask = process.StandardError.ReadToEndAsync(cancellationToken);

        process.WaitForExit();
        progressTask.GetAwaiter().GetResult();
        var errorText = errorTask.GetAwaiter().GetResult();

        cancellationToken.ThrowIfCancellationRequested();

        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException(
                $"Native extraction failed with exit code {process.ExitCode}.{Environment.NewLine}{errorText}".Trim());
        }

        progress?.Report(new InstallProgress("Extracting files...", "Finalizing extracted files...", 100, 100));
    }

    private static void PumpProgress(
        StreamReader reader,
        IProgress<InstallProgress>? progress,
        CancellationToken cancellationToken)
    {
        var buffer = new char[256];
        var tail = new StringBuilder();
        var lastPercent = -1;

        int charsRead;
        while ((charsRead = reader.Read(buffer, 0, buffer.Length)) > 0)
        {
            cancellationToken.ThrowIfCancellationRequested();
            tail.Append(buffer, 0, charsRead);

            var matches = Regex.Matches(tail.ToString(), @"(?<!\d)(\d{1,3})%");
            foreach (Match match in matches)
            {
                if (!int.TryParse(match.Groups[1].Value, out var percent))
                {
                    continue;
                }

                percent = Math.Clamp(percent, 0, 100);
                if (percent == lastPercent)
                {
                    continue;
                }

                lastPercent = percent;
                progress?.Report(new InstallProgress("Extracting files...", "Using native 7-Zip extraction...", percent, 100));
            }

            if (tail.Length > 64)
            {
                tail.Remove(0, tail.Length - 64);
            }
        }
    }
}
