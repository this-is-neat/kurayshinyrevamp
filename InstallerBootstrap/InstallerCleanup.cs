using System.Threading;

namespace InstallerBootstrap;

internal static class InstallerCleanup
{
    public static bool TryDeleteFile(string path, int maxAttempts = 5, int delayMilliseconds = 250)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return true;
        }

        for (var attempt = 0; attempt < maxAttempts; attempt++)
        {
            try
            {
                if (!File.Exists(path))
                {
                    return true;
                }

                File.SetAttributes(path, FileAttributes.Normal);
                File.Delete(path);
                if (!File.Exists(path))
                {
                    return true;
                }
            }
            catch when (attempt + 1 < maxAttempts)
            {
                Thread.Sleep(delayMilliseconds);
            }
            catch
            {
                break;
            }
        }

        return !File.Exists(path);
    }

    public static bool TryDeleteDirectory(string path, int maxAttempts = 5, int delayMilliseconds = 250)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return true;
        }

        for (var attempt = 0; attempt < maxAttempts; attempt++)
        {
            try
            {
                if (!Directory.Exists(path))
                {
                    return true;
                }

                ClearAttributesRecursively(path);
                Directory.Delete(path, recursive: true);
                if (!Directory.Exists(path))
                {
                    return true;
                }
            }
            catch when (attempt + 1 < maxAttempts)
            {
                Thread.Sleep(delayMilliseconds);
            }
            catch
            {
                break;
            }
        }

        return !Directory.Exists(path);
    }

    public static void TryDeleteEmptyDirectory(string path)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(path) &&
                Directory.Exists(path) &&
                !Directory.EnumerateFileSystemEntries(path).Any())
            {
                Directory.Delete(path);
            }
        }
        catch
        {
        }
    }

    public static void CleanupStaleFiles(string rootPath, string searchPattern, TimeSpan minimumAge)
    {
        if (!Directory.Exists(rootPath))
        {
            return;
        }

        foreach (var filePath in Directory.EnumerateFiles(rootPath, searchPattern, SearchOption.TopDirectoryOnly))
        {
            if (IsOlderThan(filePath, minimumAge))
            {
                TryDeleteFile(filePath);
            }
        }
    }

    public static void CleanupStaleDirectories(string rootPath, string searchPattern, TimeSpan minimumAge)
    {
        if (!Directory.Exists(rootPath))
        {
            return;
        }

        foreach (var directoryPath in Directory.EnumerateDirectories(rootPath, searchPattern, SearchOption.TopDirectoryOnly))
        {
            if (IsOlderThan(directoryPath, minimumAge))
            {
                TryDeleteDirectory(directoryPath);
            }
        }
    }

    public static bool IsOlderThan(string path, TimeSpan minimumAge)
    {
        try
        {
            DateTime lastWriteTimeUtc;
            if (File.Exists(path))
            {
                lastWriteTimeUtc = File.GetLastWriteTimeUtc(path);
            }
            else if (Directory.Exists(path))
            {
                lastWriteTimeUtc = Directory.GetLastWriteTimeUtc(path);
            }
            else
            {
                return false;
            }

            if (lastWriteTimeUtc == DateTime.MinValue || lastWriteTimeUtc == DateTime.MaxValue)
            {
                return false;
            }

            return DateTime.UtcNow - lastWriteTimeUtc >= minimumAge;
        }
        catch
        {
            return false;
        }
    }

    private static void ClearAttributesRecursively(string rootPath)
    {
        if (!Directory.Exists(rootPath))
        {
            return;
        }

        foreach (var filePath in Directory.EnumerateFiles(rootPath, "*", SearchOption.AllDirectories))
        {
            try
            {
                File.SetAttributes(filePath, FileAttributes.Normal);
            }
            catch
            {
            }
        }

        foreach (var directoryPath in Directory.EnumerateDirectories(rootPath, "*", SearchOption.AllDirectories))
        {
            try
            {
                File.SetAttributes(directoryPath, FileAttributes.Normal);
            }
            catch
            {
            }
        }

        try
        {
            File.SetAttributes(rootPath, FileAttributes.Normal);
        }
        catch
        {
        }
    }
}
