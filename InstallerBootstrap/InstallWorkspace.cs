namespace InstallerBootstrap;

internal sealed class InstallWorkspace : IDisposable
{
    private const string StagingPrefix = ".kif-install-";
    private const string LegacyStagingPrefix = ".kif-extract-";
    private static readonly TimeSpan StaleStagingAge = TimeSpan.FromHours(12);

    public InstallWorkspace(string targetDirectory)
    {
        InstallRoot = Path.GetFullPath(targetDirectory);
        InstallParent = Directory.GetParent(InstallRoot)?.FullName
            ?? throw new InvalidOperationException("Install directory must have a parent directory.");
        StagingRoot = Path.Combine(InstallParent, $"{StagingPrefix}{Guid.NewGuid():N}");
        ExtractedRoot = Path.Combine(StagingRoot, "PIF");
    }

    public string InstallRoot { get; }
    public string InstallParent { get; }
    public string StagingRoot { get; }
    public string ExtractedRoot { get; }

    public void Prepare()
    {
        Directory.CreateDirectory(InstallParent);
        Directory.CreateDirectory(StagingRoot);
    }

    public static void CleanupStaleStageDirectories(string targetDirectory)
    {
        var installRoot = Path.GetFullPath(targetDirectory);
        var installParent = Directory.GetParent(installRoot)?.FullName;
        if (string.IsNullOrWhiteSpace(installParent) || !Directory.Exists(installParent))
        {
            return;
        }

        CleanupStagePrefix(installParent, StagingPrefix);
        CleanupStagePrefix(installParent, LegacyStagingPrefix);
    }

    public void Dispose()
    {
        InstallerCleanup.TryDeleteDirectory(StagingRoot);
    }

    private static void CleanupStagePrefix(string installParent, string prefix)
    {
        foreach (var directoryPath in Directory.EnumerateDirectories(installParent, $"{prefix}*", SearchOption.TopDirectoryOnly))
        {
            if (InstallerCleanup.IsOlderThan(directoryPath, StaleStagingAge))
            {
                InstallerCleanup.TryDeleteDirectory(directoryPath);
            }
        }
    }
}
