using System.Net.Http;

namespace InstallerBootstrap;

internal static class PayloadLocator
{
    private static readonly byte[] TrailerMagic = "PIFINST1"u8.ToArray();
    private const int TrailerSize = 24;

    public static PayloadSource OpenPayloadSource(IProgress<InstallProgress>? progress, CancellationToken cancellationToken)
    {
        var executablePath = Application.ExecutablePath;
        var executableStream = new FileStream(executablePath, FileMode.Open, FileAccess.Read, FileShare.Read);

        if (TryReadEmbeddedPayload(executableStream, out var payloadOffset, out var payloadLength))
        {
            return new PayloadSource(
                executableStream,
                () => new SubStream(executableStream, payloadOffset, payloadLength));
        }

        executableStream.Dispose();

        var sidecarPath = Path.Combine(AppContext.BaseDirectory, ReleasePayloadManifest.SidecarArchiveName);
        if (File.Exists(sidecarPath))
        {
            return new PayloadSource(
                new FileStream(sidecarPath, FileMode.Open, FileAccess.Read, FileShare.Read),
                () => new FileStream(sidecarPath, FileMode.Open, FileAccess.Read, FileShare.Read));
        }

        return DownloadPayloadArchive(progress, cancellationToken);
    }

    private static PayloadSource DownloadPayloadArchive(IProgress<InstallProgress>? progress, CancellationToken cancellationToken)
    {
        var tempRoot = Path.Combine(Path.GetTempPath(), "KurayInfiniteFusionInstaller", ReleasePayloadManifest.ReleaseTag);
        Directory.CreateDirectory(tempRoot);

        var tempArchivePath = Path.Combine(tempRoot, ReleasePayloadManifest.PayloadArchiveName);
        if (File.Exists(tempArchivePath))
        {
            var existingLength = new FileInfo(tempArchivePath).Length;
            if (existingLength == ReleasePayloadManifest.TotalPayloadBytes)
            {
                return CreateFilePayloadSource(tempArchivePath, deleteOnDispose: false);
            }

            File.Delete(tempArchivePath);
        }

        var tempPartialPath = tempArchivePath + ".partial";
        if (File.Exists(tempPartialPath))
        {
            File.Delete(tempPartialPath);
        }

        progress?.Report(new InstallProgress("Downloading game files...", "Preparing download", 0, ReleasePayloadManifest.TotalPayloadBytes));

        using var httpClient = new HttpClient
        {
            Timeout = Timeout.InfiniteTimeSpan
        };

        long downloadedBytes = 0;

        try
        {
            using var outputStream = new FileStream(tempPartialPath, FileMode.Create, FileAccess.Write, FileShare.None);
            foreach (var assetName in ReleasePayloadManifest.PayloadPartNames)
            {
                cancellationToken.ThrowIfCancellationRequested();

                var assetUri = ReleasePayloadManifest.GetAssetUri(assetName);
                progress?.Report(new InstallProgress("Downloading game files...", assetName, downloadedBytes, ReleasePayloadManifest.TotalPayloadBytes));

                using var request = new HttpRequestMessage(HttpMethod.Get, assetUri);
                using var response = httpClient.Send(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
                response.EnsureSuccessStatusCode();

                using var responseStream = response.Content.ReadAsStream(cancellationToken);
                var buffer = new byte[1024 * 1024];
                int bytesRead;
                while ((bytesRead = responseStream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    outputStream.Write(buffer, 0, bytesRead);
                    downloadedBytes += bytesRead;
                    progress?.Report(new InstallProgress("Downloading game files...", assetName, downloadedBytes, ReleasePayloadManifest.TotalPayloadBytes));
                }
            }
        }
        catch
        {
            if (File.Exists(tempPartialPath))
            {
                File.Delete(tempPartialPath);
            }

            throw;
        }

        var finalLength = new FileInfo(tempPartialPath).Length;
        if (finalLength != ReleasePayloadManifest.TotalPayloadBytes)
        {
            File.Delete(tempPartialPath);
            throw new InvalidOperationException(
                $"Downloaded payload size mismatch. Expected {ReleasePayloadManifest.TotalPayloadBytes} bytes, got {finalLength} bytes.");
        }

        File.Move(tempPartialPath, tempArchivePath, overwrite: true);
        return CreateFilePayloadSource(tempArchivePath, deleteOnDispose: true);
    }

    private static PayloadSource CreateFilePayloadSource(string archivePath, bool deleteOnDispose)
    {
        return new PayloadSource(
            new FileStream(archivePath, FileMode.Open, FileAccess.Read, FileShare.Read),
            () => new FileStream(archivePath, FileMode.Open, FileAccess.Read, FileShare.Read),
            deleteOnDispose
                ? () =>
                {
                    try
                    {
                        if (File.Exists(archivePath))
                        {
                            File.Delete(archivePath);
                        }
                    }
                    catch
                    {
                    }
                }
                : null);
    }

    private static bool TryReadEmbeddedPayload(FileStream executableStream, out long payloadOffset, out long payloadLength)
    {
        payloadOffset = 0;
        payloadLength = 0;

        if (executableStream.Length < TrailerSize)
        {
            return false;
        }

        executableStream.Seek(-TrailerSize, SeekOrigin.End);
        Span<byte> trailer = stackalloc byte[TrailerSize];
        executableStream.ReadExactly(trailer);

        if (!trailer.Slice(0, TrailerMagic.Length).SequenceEqual(TrailerMagic))
        {
            return false;
        }

        payloadOffset = BitConverter.ToInt64(trailer.Slice(8, 8));
        payloadLength = BitConverter.ToInt64(trailer.Slice(16, 8));
        return payloadOffset >= 0 && payloadLength > 0 && payloadOffset + payloadLength <= executableStream.Length - TrailerSize;
    }
}

internal sealed class PayloadSource : IDisposable
{
    private readonly Action? _disposeAction;

    public PayloadSource(Stream containerStream, Func<Stream> createPayloadStream, Action? disposeAction = null)
    {
        ContainerStream = containerStream;
        CreatePayloadStream = createPayloadStream;
        _disposeAction = disposeAction;
    }

    public Stream ContainerStream { get; }
    public Func<Stream> CreatePayloadStream { get; }

    public void Dispose()
    {
        ContainerStream.Dispose();
        _disposeAction?.Invoke();
    }
}

internal sealed class SubStream : Stream
{
    private readonly Stream _baseStream;
    private readonly long _start;
    private readonly long _length;
    private long _position;

    public SubStream(Stream baseStream, long start, long length)
    {
        _baseStream = baseStream;
        _start = start;
        _length = length;
        _position = 0;
        _baseStream.Seek(_start, SeekOrigin.Begin);
    }

    public override bool CanRead => true;
    public override bool CanSeek => true;
    public override bool CanWrite => false;
    public override long Length => _length;

    public override long Position
    {
        get => _position;
        set => Seek(value, SeekOrigin.Begin);
    }

    public override void Flush()
    {
    }

    public override int Read(byte[] buffer, int offset, int count)
    {
        if (_position >= _length)
        {
            return 0;
        }

        var remaining = _length - _position;
        var toRead = (int)Math.Min(count, remaining);
        lock (_baseStream)
        {
            _baseStream.Seek(_start + _position, SeekOrigin.Begin);
            var bytesRead = _baseStream.Read(buffer, offset, toRead);
            _position += bytesRead;
            return bytesRead;
        }
    }

    public override int Read(Span<byte> buffer)
    {
        if (_position >= _length)
        {
            return 0;
        }

        var remaining = _length - _position;
        var toRead = (int)Math.Min(buffer.Length, remaining);
        lock (_baseStream)
        {
            _baseStream.Seek(_start + _position, SeekOrigin.Begin);
            var bytesRead = _baseStream.Read(buffer.Slice(0, toRead));
            _position += bytesRead;
            return bytesRead;
        }
    }

    public override long Seek(long offset, SeekOrigin origin)
    {
        var target = origin switch
        {
            SeekOrigin.Begin => offset,
            SeekOrigin.Current => _position + offset,
            SeekOrigin.End => _length + offset,
            _ => throw new ArgumentOutOfRangeException(nameof(origin), origin, null)
        };

        if (target < 0 || target > _length)
        {
            throw new ArgumentOutOfRangeException(nameof(offset));
        }

        _position = target;
        return _position;
    }

    public override void SetLength(long value)
    {
        throw new NotSupportedException();
    }

    public override void Write(byte[] buffer, int offset, int count)
    {
        throw new NotSupportedException();
    }
}
