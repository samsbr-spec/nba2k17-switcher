<#
  NBA 2K17 Switcher - command-line front end (the window is NBA2K17-Launcher.ps1; both use Switcher.Core.ps1).

    NBA2K17-Switcher.ps1 -Play Revival | -Play Back2Back
    NBA2K17-Switcher.ps1 -Setup [-Current Revival|Back2Back|Unknown] [-SeedRevival <folder>] [-SeedBack2Back <folder>] [-NoShortcuts]
    NBA2K17-Switcher.ps1 -Split [-DryRun]
    NBA2K17-Switcher.ps1 -Status
#>
[CmdletBinding()]
param(
    [ValidateSet('Revival', 'Back2Back')][string]$Play,
    [switch]$Setup,
    [ValidateSet('Revival', 'Back2Back', 'Unknown')][string]$Current,
    [string]$SeedRevival,
    [string]$SeedBack2Back,
    [switch]$NoShortcuts,
    [switch]$Split,
    [switch]$DryRun,
    [switch]$Status,
    [switch]$CheckUpdate,
    [switch]$Update,
    [switch]$MakeZip,
    [string]$TestSplitSource,
    [string]$TestSplitTarget,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$wantForce = [bool]$Force   # read before loading the engine: its startup resets a variable of the same name
. (Join-Path $PSScriptRoot 'Switcher.Core.ps1')

$interactive = ($Host.Name -eq 'ConsoleHost') -and -not [Console]::IsInputRedirected
$script:Force = $wantForce
$script:Say = {
    param($Message, $Level)
    switch ($Level) {
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        'WARN'  { Write-Host $Message -ForegroundColor Yellow }
        'OK'    { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}
if (-not $interactive) {
    $script:AskYesNo = { param($Prompt) Write-Host "$Prompt -> no (not interactive)"; return $false }
    $script:AskThree = { param($Prompt, $A, $B) Write-Host "$Prompt -> cancel (not interactive)"; return 'Cancel' }
}

function Pause-Console([int]$Seconds = 0) {
    if (-not $interactive) { return }
    if ($Seconds -gt 0) { Start-Sleep -Seconds $Seconds; return }
    Write-Host ''
    Write-Host 'Press Enter to close this window.'
    [void](Read-Host)
}

function Show-Status {
    $i = Get-StatusInfo
    Write-Host "NBA 2K17 Switcher $($i.version)" -ForegroundColor Cyan
    Write-Host ("Steam:              {0}" -f $(if ($i.steam) { $i.steam } else { 'not found' }))
    Write-Host ("Steam save folder:  {0}" -f $(if ($i.remote) { $i.remote } else { 'not found (start the game once through either client)' }))
    Write-Host ("  contents:         {0}" -f $i.remoteDesc)
    Write-Host ("Revival launcher:   {0}" -f $(if ($i.revivalExe) { $i.revivalExe } else { 'not found' }))
    Write-Host ("Revival game:       {0}" -f $(if ($i.revivalGame) { $i.revivalGame } else { 'unknown' }))
    Write-Host ("Back2Back launcher: {0}" -f $(if ($i.back2backExe) { $i.back2backExe } else { 'not found' }))
    Write-Host ("Back2Back game:     {0}" -f $(if ($i.back2backGame) { $i.back2backGame } else { 'unknown' }))
    if ($i.state) {
        Write-Host ("Saves in place for: {0}  (since {1})" -f $i.current, $i.lastSwitch) -ForegroundColor Cyan
        Write-Host ("Parked Revival:     {0}" -f $i.parkedRevival)
        Write-Host ("Parked Back2Back:   {0}" -f $i.parkedBack2Back)
        Write-Host ("Data folder:        {0}  ({1} history zips)" -f $script:AppDir, $i.historyCount)
    } else {
        Write-Host 'Not set up yet. Run Install.cmd.' -ForegroundColor Yellow
    }
    Write-Host ("Running now:        game={0} launchers={1}" -f $(if ($i.gameRunning) { 'yes' } else { 'no' }), $(if ($i.launchers.Count) { $i.launchers -join ', ' } else { 'none' }))
    switch ($i.plan.kind) {
        'shared'  { Write-Host 'WARNING: both clients use the SAME game folder. Run Install.cmd or Split.cmd once to give Back2Back its own copy.' -ForegroundColor Yellow }
        'prepare' { Write-Host "Back2Back is not set up yet. Install.cmd can prepare its copy of the game now ($($i.plan.target)) so the two never share a folder." -ForegroundColor Yellow }
        'repoint' { Write-Host "A Back2Back copy exists at $($i.plan.target). Point Back2Back at the NBA2K17.exe in it (Install.cmd does this when Back2Back is installed)." -ForegroundColor Yellow }
        'wait'    { Write-Host $i.plan.note -ForegroundColor Yellow }
    }
}

try {
    if ($Setup) {
        $cur = $Current
        if (-not $cur -and $interactive) {
            $i = Get-StatusInfo
            Write-Host ("The Steam save folder currently holds: {0}" -f $i.remoteDesc)
            Write-Host 'Whose saves are these, i.e. which client did you play LAST on this PC?'
            $a = Read-Host 'Type R for Revival, B for Back2Back, or U if you are not sure'
            switch -Regex ($a) { '^[Rr]' { $cur = 'Revival' } '^[Bb]' { $cur = 'Back2Back' } default { $cur = 'Unknown' } }
        }
        [void](Invoke-Setup -CurrentClient $cur -SeedRevival $SeedRevival -SeedBack2Back $SeedBack2Back -NoShortcuts:$NoShortcuts)
        Pause-Console
        exit 0
    }
    if ($Split) { Invoke-Split -DryRun:$DryRun -Confirmed:$Force -TestSource $TestSplitSource -TestTarget $TestSplitTarget; Pause-Console; exit 0 }
    if ($MakeZip) {
        $out = New-ReleaseZip
        Write-Host "Release zip ready: $out" -ForegroundColor Green
        Write-Host ''
        Write-Host "To publish version $($script:Version):"
        Write-Host '  1. On GitHub open your repository > Releases > "Draft a new release".'
        Write-Host "  2. Tag: v$($script:Version)   Title: NBA 2K17 Switcher $($script:Version)"
        Write-Host '  3. Drag the zip above into the release and press "Publish release".'
        Write-Host '  Your friend''s launcher offers the update the next time it opens.'
        Pause-Console
        exit 0
    }
    if ($CheckUpdate -or $Update) {
        $u = Get-UpdateInfo
        if (-not $u.configured) { Write-Host 'No update source set up yet (update.json has no GitHub owner/repo).' -ForegroundColor Yellow }
        elseif ($u.error) { Write-Host "Could not check for updates: $($u.error)" -ForegroundColor Yellow }
        elseif ($u.available) {
            Write-Host "Version $($u.latest) is available (you have $($u.local))." -ForegroundColor Cyan
            if ($Update) {
                [void](Invoke-Update $u.url $u.latest)
                Write-Host 'Done. Open the launcher again to use the new version.' -ForegroundColor Green
            } else { Write-Host 'Run Update.cmd (or click the update button in the launcher) to install it.' }
        } else { Write-Host "Up to date (version $($u.local))." -ForegroundColor Green }
        Pause-Console
        exit 0
    }
    if ($Play) {
        $r = Invoke-Play $Play
        Write-Host ''
        Write-Host $r.advice -ForegroundColor Cyan
        Pause-Console 6
        exit 0
    }
    Show-Status
    Pause-Console
    exit 0
} catch {
    $msg = $_.Exception.Message -replace '^SWITCHER: ', ''
    Write-Host $msg -ForegroundColor Red
    Pause-Console
    exit 1
}
