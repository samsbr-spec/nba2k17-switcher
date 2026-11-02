// Tiny stub so the launcher window has its own icon, taskbar entry and no console: it just starts
// NBA2K17-Launcher.ps1 (which sits next to this exe) hidden in PowerShell.
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

static class Program
{
    [STAThread]
    static void Main()
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(dir, "NBA2K17-Launcher.ps1");
        if (!File.Exists(script))
        {
            MessageBox.Show("NBA2K17-Launcher.ps1 was not found next to this program.\n\nKeep 'NBA 2K17 Launcher.exe' inside the NBA2K17-Switcher folder.",
                "NBA 2K17 Launcher", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        string ps = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), @"System32\WindowsPowerShell\v1.0\powershell.exe");
        var psi = new ProcessStartInfo
        {
            FileName = ps,
            Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File \"" + script + "\"",
            WorkingDirectory = dir,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        try { Process.Start(psi); }
        catch (Exception ex)
        {
            MessageBox.Show("Could not start the launcher window:\n" + ex.Message, "NBA 2K17 Launcher", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
