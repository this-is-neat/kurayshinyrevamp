namespace InstallerBootstrap;

internal sealed class InstallerForm : Form
{
    private readonly InstallerOptions _initialOptions;
    private readonly TextBox _installPathTextBox;
    private readonly Label _statusLabel;
    private readonly Label _detailLabel;
    private readonly ProgressBar _progressBar;
    private readonly Button _installButton;
    private readonly Button _browseButton;
    private readonly Button _cancelButton;
    private CancellationTokenSource? _installCancellation;

    public InstallerForm(InstallerOptions options)
    {
        _initialOptions = options;

        Text = "Kuray Infinite Fusion Installer";
        Width = 700;
        Height = 260;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;
        MaximizeBox = false;
        MinimizeBox = false;

        var introLabel = new Label
        {
            Left = 20,
            Top = 20,
            Width = 640,
            Height = 40,
            Text = "Install Kuray Infinite Fusion to your Games folder. If the game files are not bundled with this installer, it will download them from GitHub first."
        };

        var pathLabel = new Label
        {
            Left = 20,
            Top = 70,
            Width = 120,
            Text = "Install location"
        };

        _installPathTextBox = new TextBox
        {
            Left = 20,
            Top = 95,
            Width = 540,
            Text = _initialOptions.TargetDirectory
        };

        _browseButton = new Button
        {
            Left = 570,
            Top = 93,
            Width = 90,
            Text = "Browse..."
        };
        _browseButton.Click += BrowseButton_Click;

        _statusLabel = new Label
        {
            Left = 20,
            Top = 130,
            Width = 640,
            Text = "Ready to install."
        };

        _detailLabel = new Label
        {
            Left = 20,
            Top = 150,
            Width = 640,
            Text = string.Empty
        };

        _progressBar = new ProgressBar
        {
            Left = 20,
            Top = 175,
            Width = 640,
            Height = 18,
            Style = ProgressBarStyle.Continuous
        };

        _installButton = new Button
        {
            Left = 470,
            Top = 205,
            Width = 90,
            Text = "Install"
        };
        _installButton.Click += InstallButton_Click;

        _cancelButton = new Button
        {
            Left = 570,
            Top = 205,
            Width = 90,
            Text = "Cancel"
        };
        _cancelButton.Click += CancelButton_Click;

        Controls.Add(introLabel);
        Controls.Add(pathLabel);
        Controls.Add(_installPathTextBox);
        Controls.Add(_browseButton);
        Controls.Add(_statusLabel);
        Controls.Add(_detailLabel);
        Controls.Add(_progressBar);
        Controls.Add(_installButton);
        Controls.Add(_cancelButton);
    }

    private void BrowseButton_Click(object? sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Choose where Kuray Infinite Fusion should be installed.",
            SelectedPath = _installPathTextBox.Text,
            ShowNewFolderButton = true
        };

        if (dialog.ShowDialog(this) == DialogResult.OK)
        {
            _installPathTextBox.Text = dialog.SelectedPath;
        }
    }

    private async void InstallButton_Click(object? sender, EventArgs e)
    {
        var targetDirectory = _installPathTextBox.Text.Trim();
        if (string.IsNullOrWhiteSpace(targetDirectory))
        {
            MessageBox.Show(this, "Choose an install folder first.", "Installer", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        if (Directory.Exists(targetDirectory) && Directory.EnumerateFileSystemEntries(targetDirectory).Any())
        {
            var overwriteResult = MessageBox.Show(
                this,
                "The target folder already contains files. Continue and overwrite matching files?",
                "Installer",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (overwriteResult != DialogResult.Yes)
            {
                return;
            }
        }

        ToggleUi(isInstalling: true);
        _installCancellation = new CancellationTokenSource();
        _progressBar.Value = 0;

        var progress = new Progress<InstallProgress>(UpdateProgress);
        var options = new InstallerOptions
        {
            TargetDirectory = targetDirectory,
            Silent = false,
            SkipShortcuts = false
        };

        try
        {
            await Task.Run(() => InstallerEngine.Install(options, progress, _installCancellation.Token));
            _statusLabel.Text = "Installation complete.";
            _detailLabel.Text = targetDirectory;

            var launchResult = MessageBox.Show(
                this,
                "Kuray Infinite Fusion is installed. Launch it now?",
                "Installer",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Information);

            if (launchResult == DialogResult.Yes)
            {
                var gamePath = Path.Combine(targetDirectory, "Game.exe");
                if (File.Exists(gamePath))
                {
                    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = gamePath,
                        WorkingDirectory = targetDirectory,
                        UseShellExecute = true
                    });
                }
            }

            Close();
        }
        catch (OperationCanceledException)
        {
            _statusLabel.Text = "Installation canceled.";
            _detailLabel.Text = string.Empty;
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, ex.Message, "Installer Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _statusLabel.Text = "Installation failed.";
            _detailLabel.Text = string.Empty;
        }
        finally
        {
            _installCancellation?.Dispose();
            _installCancellation = null;
            ToggleUi(isInstalling: false);
        }
    }

    private void CancelButton_Click(object? sender, EventArgs e)
    {
        if (_installCancellation is not null)
        {
            _installCancellation.Cancel();
            return;
        }

        Close();
    }

    private void ToggleUi(bool isInstalling)
    {
        _installButton.Enabled = !isInstalling;
        _browseButton.Enabled = !isInstalling;
        _installPathTextBox.Enabled = !isInstalling;
        _cancelButton.Text = isInstalling ? "Stop" : "Cancel";
    }

    private void UpdateProgress(InstallProgress progress)
    {
        _statusLabel.Text = progress.Phase;
        _detailLabel.Text = progress.Detail;

        if (progress.TotalBytes <= 0)
        {
            _progressBar.Value = 0;
            return;
        }

        var percentage = (int)Math.Clamp(progress.ExtractedBytes * 100 / progress.TotalBytes, 0, 100);
        _progressBar.Value = percentage;
    }
}
