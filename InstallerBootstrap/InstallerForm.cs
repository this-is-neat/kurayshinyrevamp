namespace InstallerBootstrap;

internal sealed class InstallerForm : Form
{
    private readonly InstallerOptions _initialOptions;
    private readonly TextBox _installPathTextBox;
    private readonly Label _statusLabel;
    private readonly Label _detailLabel;
    private readonly ProgressBar _progressBar;
    private readonly Button _installButton;
    private readonly Button _updateButton;
    private readonly Button _browseButton;
    private readonly Button _cancelButton;
    private CancellationTokenSource? _installCancellation;
    private bool _closeAfterInstallStops;
    private bool _allowClose;

    public InstallerForm(InstallerOptions options)
    {
        _initialOptions = options;

        Text = "Kuray Infinite Fusion Installer";
        AutoScaleMode = AutoScaleMode.Dpi;
        ClientSize = new Size(720, 330);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;
        MaximizeBox = false;
        MinimizeBox = false;

        var introLabel = new Label
        {
            Left = 20,
            Top = 20,
            Width = 680,
            Height = 58,
            Text = "Install / Repair can set up the full game and fetch the base release if this folder still needs it. Update Only skips the big base download and applies just the latest bundled changed files to an existing install."
        };

        var pathLabel = new Label
        {
            Left = 20,
            Top = 84,
            Width = 140,
            Text = "Game folder"
        };

        _installPathTextBox = new TextBox
        {
            Left = 20,
            Top = 109,
            Width = 540,
            Text = _initialOptions.TargetDirectory
        };

        _browseButton = new Button
        {
            Left = 570,
            Top = 107,
            Width = 90,
            Text = "Browse..."
        };
        _browseButton.Click += BrowseButton_Click;

        var modeHintLabel = new Label
        {
            Left = 20,
            Top = 142,
            Width = 680,
            Height = 34,
            Text = "Use Update Only when this folder already contains Game.exe plus the Data, Graphics, and Mods folders."
        };

        _statusLabel = new Label
        {
            Left = 20,
            Top = 186,
            Width = 680,
            Text = _initialOptions.UpdateOnly ? "Ready to apply the latest update." : "Ready to install."
        };

        _detailLabel = new Label
        {
            Left = 20,
            Top = 208,
            Width = 680,
            Text = string.Empty
        };

        _progressBar = new ProgressBar
        {
            Left = 20,
            Top = 236,
            Width = 680,
            Height = 18,
            Style = ProgressBarStyle.Continuous
        };

        _installButton = new Button
        {
            Left = 350,
            Top = 272,
            Width = 130,
            Text = "Install / Repair"
        };
        _installButton.Click += InstallButton_Click;

        _updateButton = new Button
        {
            Left = 490,
            Top = 272,
            Width = 100,
            Text = "Update Only"
        };
        _updateButton.Click += UpdateButton_Click;

        _cancelButton = new Button
        {
            Left = 600,
            Top = 272,
            Width = 100,
            Text = "Cancel"
        };
        _cancelButton.Click += CancelButton_Click;
        FormClosing += InstallerForm_FormClosing;

        AcceptButton = _initialOptions.UpdateOnly ? _updateButton : _installButton;
        CancelButton = _cancelButton;

        Controls.Add(introLabel);
        Controls.Add(pathLabel);
        Controls.Add(_installPathTextBox);
        Controls.Add(_browseButton);
        Controls.Add(modeHintLabel);
        Controls.Add(_statusLabel);
        Controls.Add(_detailLabel);
        Controls.Add(_progressBar);
        Controls.Add(_installButton);
        Controls.Add(_updateButton);
        Controls.Add(_cancelButton);
    }

    private void BrowseButton_Click(object? sender, EventArgs e)
    {
        using var dialog = new FolderBrowserDialog
        {
            Description = "Choose where Kuray Infinite Fusion should be installed or updated.",
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
        await RunRequestedOperationAsync(updateOnly: false);
    }

    private async void UpdateButton_Click(object? sender, EventArgs e)
    {
        await RunRequestedOperationAsync(updateOnly: true);
    }

    private async Task RunRequestedOperationAsync(bool updateOnly)
    {
        var targetDirectory = _installPathTextBox.Text.Trim();
        if (string.IsNullOrWhiteSpace(targetDirectory))
        {
            MessageBox.Show(this, "Choose a game folder first.", "Installer", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        if (updateOnly)
        {
            if (!ReleasePayloadManifest.LooksLikeGameInstall(targetDirectory))
            {
                MessageBox.Show(
                    this,
                    "Update Only needs an existing Kuray Infinite Fusion install folder. Choose the folder that already contains Game.exe plus the Data, Graphics, and Mods folders, or use Install / Repair instead.",
                    "Installer",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                return;
            }

            var updateResult = MessageBox.Show(
                this,
                "Apply only the latest bundled changed files to this existing install?",
                "Installer",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (updateResult != DialogResult.Yes)
            {
                return;
            }
        }
        else if (Directory.Exists(targetDirectory) && Directory.EnumerateFileSystemEntries(targetDirectory).Any())
        {
            var overwriteResult = MessageBox.Show(
                this,
                "The target folder already contains files. Continue and overwrite matching files or download any missing base files?",
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
        _statusLabel.Text = updateOnly ? "Applying update..." : "Preparing installation...";
        _detailLabel.Text = targetDirectory;

        var progress = new Progress<InstallProgress>(UpdateProgress);
        var options = new InstallerOptions
        {
            TargetDirectory = targetDirectory,
            Silent = false,
            SkipShortcuts = false,
            UpdateOnly = updateOnly
        };

        try
        {
            await Task.Run(() => InstallerEngine.Install(options, progress, _installCancellation.Token));
            _statusLabel.Text = updateOnly ? "Update complete." : "Installation complete.";
            _detailLabel.Text = targetDirectory;

            var launchResult = MessageBox.Show(
                this,
                updateOnly
                    ? "Kuray Infinite Fusion was updated. Launch it now?"
                    : "Kuray Infinite Fusion is installed. Launch it now?",
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

            _allowClose = true;
            Close();
        }
        catch (OperationCanceledException)
        {
            _statusLabel.Text = updateOnly ? "Update canceled." : "Installation canceled.";
            _detailLabel.Text = "Temporary files cleaned up.";
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, ex.Message, "Installer Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _statusLabel.Text = updateOnly ? "Update failed." : "Installation failed.";
            _detailLabel.Text = string.Empty;
        }
        finally
        {
            _installCancellation?.Dispose();
            _installCancellation = null;
            ToggleUi(isInstalling: false);
            if (_closeAfterInstallStops)
            {
                _closeAfterInstallStops = false;
                _allowClose = true;
                Close();
            }
        }
    }

    private void CancelButton_Click(object? sender, EventArgs e)
    {
        if (_installCancellation is not null)
        {
            RequestCancellation();
            return;
        }

        Close();
    }

    private void ToggleUi(bool isInstalling)
    {
        _installButton.Enabled = !isInstalling;
        _updateButton.Enabled = !isInstalling;
        _browseButton.Enabled = !isInstalling;
        _installPathTextBox.Enabled = !isInstalling;
        _cancelButton.Enabled = true;
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

    private void InstallerForm_FormClosing(object? sender, FormClosingEventArgs e)
    {
        if (_allowClose || _installCancellation is null)
        {
            return;
        }

        e.Cancel = true;
        _closeAfterInstallStops = true;
        RequestCancellation();
    }

    private void RequestCancellation()
    {
        if (_installCancellation is null || _installCancellation.IsCancellationRequested)
        {
            return;
        }

        _statusLabel.Text = "Canceling installation...";
        _detailLabel.Text = "Cleaning up temporary files...";
        _cancelButton.Enabled = false;
        _installCancellation.Cancel();
    }
}
