namespace InstallerBootstrap;

internal enum PayloadSourceMode
{
    DownloadOnly,
    EmbeddedOrSidecarOnly,
    EmbeddedOrSidecarOrDownload
}

internal sealed record PayloadPackageManifest(
    string PackageId,
    string DisplayName,
    string ReleaseTag,
    string PayloadArchiveName,
    long TotalPayloadBytes,
    IReadOnlyList<string> PayloadPartNames,
    PayloadSourceMode SourceMode,
    string? SidecarArchiveName = null)
{
    public Uri GetAssetUri(string assetName)
    {
        return new Uri(
            $"https://github.com/{ReleasePayloadManifest.RepositoryOwner}/{ReleasePayloadManifest.RepositoryName}/releases/download/{ReleaseTag}/{assetName}");
    }
}

internal static class ReleasePayloadManifest
{
    public const string RepositoryOwner = "this-is-neat";
    public const string RepositoryName = "kurayshinyrevamp";

    public static PayloadPackageManifest BasePackage { get; } = new(
        PackageId: "base-2026-04-22-no-csf",
        DisplayName: "Base game files",
        ReleaseTag: "2026-04-22-no-csf",
        PayloadArchiveName: "PIF-player-build-20260422-no-csf.7z",
        TotalPayloadBytes: 12010902461,
        PayloadPartNames: new[]
        {
            "PIF-player-build-20260422-no-csf.payload.part001",
            "PIF-player-build-20260422-no-csf.payload.part002",
            "PIF-player-build-20260422-no-csf.payload.part003",
            "PIF-player-build-20260422-no-csf.payload.part004",
            "PIF-player-build-20260422-no-csf.payload.part005",
            "PIF-player-build-20260422-no-csf.payload.part006",
            "PIF-player-build-20260422-no-csf.payload.part007",
            "PIF-player-build-20260422-no-csf.payload.part008",
            "PIF-player-build-20260422-no-csf.payload.part009"
        },
        SourceMode: PayloadSourceMode.DownloadOnly);

    public static PayloadPackageManifest CurrentUpdatePackage { get; } = new(
        PackageId: "embedded-update-2026-04-22a",
        DisplayName: "Latest changed files update",
        ReleaseTag: string.Empty,
        PayloadArchiveName: "PIF-player-build-20260422-no-csf-update1.7z",
        TotalPayloadBytes: 0,
        PayloadPartNames: Array.Empty<string>(),
        SourceMode: PayloadSourceMode.EmbeddedOrSidecarOnly,
        SidecarArchiveName: "PIF-player-build-20260422-no-csf-update1.7z");

    public static IReadOnlyList<PayloadPackageManifest> GetPackagesForInstall(string installRoot)
    {
        var packages = new List<PayloadPackageManifest>();
        if (!LooksLikeBaseInstall(installRoot))
        {
            packages.Add(BasePackage);
        }

        packages.Add(CurrentUpdatePackage);
        return packages;
    }

    public static bool LooksLikeBaseInstall(string installRoot)
    {
        var fullInstallRoot = Path.GetFullPath(installRoot);
        return File.Exists(Path.Combine(fullInstallRoot, "Game.exe")) &&
               File.Exists(Path.Combine(fullInstallRoot, "Game.ini")) &&
               File.Exists(Path.Combine(fullInstallRoot, "PACKAGED_BUILD_MANIFEST.txt")) &&
               Directory.Exists(Path.Combine(fullInstallRoot, "Data")) &&
               Directory.Exists(Path.Combine(fullInstallRoot, "Graphics")) &&
               Directory.Exists(Path.Combine(fullInstallRoot, "Mods"));
    }
}
