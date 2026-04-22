namespace InstallerBootstrap;

internal static class ReleasePayloadManifest
{
    public const string RepositoryOwner = "this-is-neat";
    public const string RepositoryName = "kurayshinyrevamp";
    public const string ReleaseTag = "2026-04-22-no-csf";
    public const string SidecarArchiveName = "PIF-player-build-20260422-no-csf.7z";
    public const string PayloadArchiveName = "PIF-player-build-20260422-no-csf.7z";
    public const long TotalPayloadBytes = 12010902461;

    public static IReadOnlyList<string> PayloadPartNames { get; } = new[]
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
    };

    public static Uri GetAssetUri(string assetName)
    {
        return new Uri($"https://github.com/{RepositoryOwner}/{RepositoryName}/releases/download/{ReleaseTag}/{assetName}");
    }
}
