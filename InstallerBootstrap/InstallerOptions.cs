namespace InstallerBootstrap;

internal sealed class InstallerOptions
{
    public string TargetDirectory { get; init; } = GetDefaultInstallDirectory();
    public bool Silent { get; init; }
    public bool SkipShortcuts { get; init; }

    public static InstallerOptions Parse(string[] args)
    {
        var targetDirectory = GetDefaultInstallDirectory();
        var silent = false;
        var skipShortcuts = false;

        foreach (var arg in args)
        {
            if (arg.Equals("/silent", StringComparison.OrdinalIgnoreCase) ||
                arg.Equals("--silent", StringComparison.OrdinalIgnoreCase))
            {
                silent = true;
                continue;
            }

            if (arg.Equals("/skipshortcuts", StringComparison.OrdinalIgnoreCase) ||
                arg.Equals("--skip-shortcuts", StringComparison.OrdinalIgnoreCase))
            {
                skipShortcuts = true;
                continue;
            }

            if (arg.StartsWith("/target=", StringComparison.OrdinalIgnoreCase))
            {
                targetDirectory = arg.Substring("/target=".Length).Trim('"');
                continue;
            }

            if (arg.StartsWith("--target=", StringComparison.OrdinalIgnoreCase))
            {
                targetDirectory = arg.Substring("--target=".Length).Trim('"');
            }
        }

        return new InstallerOptions
        {
            TargetDirectory = targetDirectory,
            Silent = silent,
            SkipShortcuts = skipShortcuts
        };
    }

    public static string GetDefaultInstallDirectory()
    {
        var userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        return Path.Combine(userProfile, "Games", "Kuray Infinite Fusion");
    }
}
