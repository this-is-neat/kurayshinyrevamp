namespace InstallerBootstrap;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        var options = InstallerOptions.Parse(args);

        if (options.Silent)
        {
            try
            {
                InstallerEngine.Install(options, progress: null, CancellationToken.None);
                Environment.ExitCode = 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex);
                Environment.ExitCode = 1;
            }

            return;
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new InstallerForm(options));
    }
}
