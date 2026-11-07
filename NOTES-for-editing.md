# Notes for editing this launcher (for a future Claude session or anyone else)

What it is: a Windows launcher for NBA 2K17 community servers (Revival and Back2Back). Both clients
share one Steam save folder (`Steam\userdata\<account>\480\remote`) and each uploads whatever is in it
to its own cloud at Play, so the launcher parks one client's saves and places the other's before it
starts the chosen client. PowerShell 5.1, no build step, no dependencies.

## Where things live
- `NBA2K17-Launcher.ps1` - the window (WPF in XAML inside the script). Tile names, taglines, sticker
  text, status wording, the "GAME ON!" flash and the colours are all in the XAML block near the top.
- `Switcher.Core.ps1` - the engine: detection (Steam, save folder, launcher exes, game folders),
  parking/placing saves, the one-time folder split, the self-updater, the installer logic.
  `$script:Version` at the top is the version number. Bump it for every release.
- `NBA2K17-Switcher.ps1` - command-line front end (-Play, -Setup, -Split, -Status, -Update, -MakeZip).
- `Launcher\NBA2K17Launcher.cs` + `app.ico` - tiny exe stub compiled on each PC by Install.cmd.
- `update.json` - which GitHub repository the launcher checks for new releases.
- `data\` (not in git) - per-PC state: parked saves, history zips, log.

## Releasing a change
1. Edit, then bump `$script:Version` in `Switcher.Core.ps1` (e.g. '2.3').
2. Run `Make-Zip.cmd` (or `NBA2K17-Switcher.ps1 -MakeZip`): writes `..\NBA2K17-Switcher-v2.3.zip`.
3. Commit and push, then create a GitHub release tagged `v2.3` with that zip attached
   (`gh release create v2.3 <zip> --repo <owner>/<repo> --title "NBA 2K17 Switcher 2.3" --notes "..."`,
   or drag the zip onto a new release on the website).
Every installed launcher offers the update on its next start. The update keeps `data\` and rebuilds
the exe only if the .cs changed.

## Testing without touching real saves
- `NBA2K17-Switcher.ps1 -Split -Force -TestSplitSource <scratch folder> -TestSplitTarget <scratch copy>`
  runs the copy step on a scratch folder and never touches the clients.
- `Get-SplitPlan` (dot-source the core) classifies the folder situation: none / shared / prepare / repoint / wait.
- Start the window with `powershell -STA -File NBA2K17-Launcher.ps1`; it reads state only until a tile is clicked.

## Things learned the hard way
- Parameters of a script that dot-sources the core share its script scope: read your own switches
  before the dot-source line (the core sets `$script:Force`).
- In a WPF ControlTemplate, trigger Setters cannot target a transform (not a FrameworkElement); animate with
  Storyboards instead.
- Windows 11 Smart App Control blocks the unsigned exe; setup detects it and points the icon at the script.
- Back2Back uploads whatever is in the save folder at Play and at exit, and never restores the other
  client's set; Revival uploads at Play only. Hence the parking.
