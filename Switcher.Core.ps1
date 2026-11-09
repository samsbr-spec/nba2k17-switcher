# Shared engine of the NBA 2K17 Switcher. Used by NBA2K17-Switcher.ps1 (command line) and NBA2K17-Launcher.ps1 (window).
# Dot-source this file; then set $script:Say / $script:AskYesNo / $script:AskThree if you want output and questions
# to go somewhere other than the console.

$script:Version = '2.3'
$script:Root = $PSScriptRoot
$script:UpdateConfig = Join-Path $PSScriptRoot 'update.json'
$script:AppDir = Join-Path $script:Root 'data'
$script:StateFile = Join-Path $script:AppDir 'state.json'
$script:ParkingRoot = Join-Path $script:AppDir 'parking'
$script:HistoryDir = Join-Path $script:AppDir 'history'
$script:LogFile = Join-Path $script:AppDir 'switcher.log'
$script:CliScript = Join-Path $script:Root 'NBA2K17-Switcher.ps1'
$script:GuiScript = Join-Path $script:Root 'NBA2K17-Launcher.ps1'
$script:ExePath = Join-Path $script:Root 'NBA 2K17 Launcher.exe'
$script:IconPath = Join-Path $script:Root 'Launcher\app.ico'
$script:PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

# Output / question hooks (the console script and the window replace these).
$script:Say = { param($Message, $Level) Write-Host $Message }
$script:AskYesNo = { param($Prompt) $a = Read-Host "$Prompt (y/n)"; return ($a -match '^[Yy]') }
$script:AskThree = { param($Prompt, $LabelA, $LabelB) $a = Read-Host "$Prompt  [A] $LabelA  [B] $LabelB  [C] cancel"; switch -Regex ($a) { '^[Aa]' { 'A' } '^[Bb]' { 'B' } default { 'Cancel' } } }
$script:NoWait = $false      # window mode: never block waiting for Back2Back's upload, report instead
$script:Force = $false       # skip confirmations

# ---------------------------------------------------------------- logging

function Write-Log([string]$Message, [string]$Level = 'INFO') {
    if (-not (Test-Path $script:AppDir)) { New-Item -ItemType Directory -Force $script:AppDir | Out-Null }
    $line = "{0:yyyy-MM-dd HH:mm:ss}  {1,-5} {2}" -f (Get-Date), $Level, $Message
    try { Add-Content -Path $script:LogFile -Value $line -Encoding UTF8 } catch {}
    & $script:Say $Message $Level
}

function Fail([string]$Message) {
    Write-Log $Message 'ERROR'
    throw "SWITCHER: $Message"
}

# ---------------------------------------------------------------- detection

function Get-SteamPath {
    $p = $null
    try { $p = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath } catch {}
    if (-not $p) { try { $p = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -ErrorAction Stop).InstallPath } catch {} }
    if (-not $p) { $p = Join-Path ${env:ProgramFiles(x86)} 'Steam' }
    $p = $p -replace '/', '\'
    if (-not (Test-Path $p)) { return $null }
    return $p
}

function Get-ActiveSteamAccount {
    try { return [int](Get-ItemProperty 'HKCU:\Software\Valve\Steam\ActiveProcess' -ErrorAction Stop).ActiveUser } catch { return 0 }
}

function Find-RemoteFolder([string]$SteamPath, [switch]$CreateIfMissing) {
    $userdata = Join-Path $SteamPath 'userdata'
    if (-not (Test-Path $userdata)) { return $null }
    $candidates = @(Get-ChildItem $userdata -Directory | Where-Object { Test-Path (Join-Path $_.FullName '480\remote') })
    if ($candidates.Count -eq 0 -and $CreateIfMissing) {
        # Nobody has run the game through a client yet. Steam creates this folder on the first run; we can make it now
        # for the signed-in account so setup can finish before that first run.
        $active = Get-ActiveSteamAccount
        if ($active -gt 0 -and (Test-Path (Join-Path $userdata "$active"))) {
            $r = Join-Path $userdata "$active\480\remote"
            New-Item -ItemType Directory -Force $r | Out-Null
            Write-Log "Created the Steam save folder for app 480 ($r); the game fills it on its first run."
            return $r
        }
    }
    if ($candidates.Count -eq 0) { return $null }
    $active = Get-ActiveSteamAccount
    if ($active -gt 0) {
        $match = $candidates | Where-Object { $_.Name -eq "$active" } | Select-Object -First 1
        if ($match) { return (Join-Path $match.FullName '480\remote') }
    }
    if ($candidates.Count -eq 1) { return (Join-Path $candidates[0].FullName '480\remote') }
    $newest = $candidates | Sort-Object { (Get-Item (Join-Path $_.FullName '480\remote')).LastWriteTime } -Descending | Select-Object -First 1
    Write-Log "Several Steam accounts have NBA 2K17 saves; using the most recently used one ($($newest.Name))." 'WARN'
    return (Join-Path $newest.FullName '480\remote')
}

function Find-Launcher([string]$Client) {
    $defaults = @{
        'Revival'   = (Join-Path $env:LOCALAPPDATA 'Revival Client\revival-client.exe')
        'Back2Back' = (Join-Path $env:LOCALAPPDATA 'BACK2BACK17\Application\BACK2BACK17.exe')
    }
    $exeName = @{ 'Revival' = 'revival-client.exe'; 'Back2Back' = 'BACK2BACK17.exe' }
    if (Test-Path $defaults[$Client]) { return $defaults[$Client] }
    $pattern = @{ 'Revival' = 'Revival'; 'Back2Back' = 'BACK2BACK17' }[$Client]
    foreach ($root in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
        foreach ($k in (Get-ChildItem $root -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue
            if ($p.DisplayName -and $p.DisplayName -like "*$pattern*") {
                $dirs = @()
                if ($p.InstallLocation) { $dirs += $p.InstallLocation }
                if ($p.DisplayIcon) { try { $dirs += (Split-Path (($p.DisplayIcon -replace ',\d+$', '').Trim('"'))) } catch {} }
                foreach ($dir in $dirs) {
                    if ($dir -and (Test-Path $dir)) {
                        $hit = Get-ChildItem -Path $dir -Recurse -Filter $exeName[$Client] -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($hit) { return $hit.FullName }
                    }
                }
            }
        }
    }
    return $null
}

function Get-GameProcess { Get-Process | Where-Object { $_.Name -match '^NBA2K17' } }
function Get-LauncherProcesses { Get-Process | Where-Object { $_.Name -eq 'revival-client' -or $_.Name -like 'BACK2BACK17*' } }

function Get-ClientGameFolder([string]$Client) {
    try {
        if ($Client -eq 'Back2Back') {
            $cfg = Join-Path $env:LOCALAPPDATA 'Rebirth2K17\config.json'
            if (Test-Path $cfg) { $gp = (Get-Content $cfg -Raw | ConvertFrom-Json).game_path; if ($gp) { return (Split-Path $gp) } }
        } else {
            $lib = Join-Path $env:APPDATA '.revival\library.json'
            if (Test-Path $lib) {
                $g = (Get-Content $lib -Raw | ConvertFrom-Json).games | Where-Object { $_.id -eq '2k17' -or $_.appName -like '*2K17*' } | Select-Object -First 1
                if ($g) { if ($g.installDir) { return $g.installDir } elseif ($g.exePath) { return (Split-Path $g.exePath) } }
            }
        }
    } catch {}
    return $null
}

function Test-SharedGameFolder {
    $r = Get-ClientGameFolder 'Revival'; $b = Get-ClientGameFolder 'Back2Back'
    return ($r -and $b -and ($r.TrimEnd('\') -ieq $b.TrimEnd('\')))
}

# ---------------------------------------------------------------- state and files

function Load-State {
    if (-not (Test-Path $script:StateFile)) { return $null }
    $obj = Get-Content $script:StateFile -Raw | ConvertFrom-Json
    $h = @{}
    foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = $p.Value }
    return $h
}

function Save-State([hashtable]$State) {
    if (-not (Test-Path $script:AppDir)) { New-Item -ItemType Directory -Force $script:AppDir | Out-Null }
    ($State | ConvertTo-Json -Depth 4) | Set-Content $script:StateFile -Encoding UTF8
}

function Get-Entries([string]$Dir) {
    if (-not (Test-Path $Dir)) { return @() }
    return @(Get-ChildItem -Force $Dir)
}

function Get-Signature([string]$Dir) {
    $sig = @{}
    foreach ($f in (Get-Entries $Dir | Where-Object { -not $_.PSIsContainer })) {
        $sig[$f.Name] = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
    }
    return $sig
}

# Small files the game writes with the same bytes for both clients. They say nothing about whose saves a folder holds.
$script:SharedSaveFiles = 'CreatedPlayers', 'RosterDescriptions', 'UserDataTattoos'

function Get-DistinctSignature([string]$Dir) {
    # Get-Signature without the files both clients have in common.
    $sig = Get-Signature $Dir
    foreach ($n in $script:SharedSaveFiles) { $sig.Remove($n) }
    return $sig
}

function Count-Identical([hashtable]$A, [hashtable]$B) {
    $n = 0
    foreach ($k in $A.Keys) { if ($B.ContainsKey($k) -and $B[$k] -eq $A[$k]) { $n++ } }
    return $n
}

function Reset-Folder([string]$Dir) {
    if (Test-Path $Dir) { Get-ChildItem -Force $Dir | Remove-Item -Recurse -Force }
    else { New-Item -ItemType Directory -Force $Dir | Out-Null }
}

function Move-Contents([string]$From, [string]$To) {
    Reset-Folder $To
    foreach ($e in (Get-Entries $From)) { Move-Item -LiteralPath $e.FullName -Destination $To -Force }
}

function Copy-Contents([string]$From, [string]$To) {
    if (-not (Test-Path $To)) { New-Item -ItemType Directory -Force $To | Out-Null }
    foreach ($e in (Get-Entries $From)) { Copy-Item -LiteralPath $e.FullName -Destination $To -Recurse -Force }
}

function Zip-Contents([string]$Dir, [string]$ZipPath) {
    $entries = Get-Entries $Dir
    if ($entries.Count -eq 0) { return $false }
    if (-not (Test-Path (Split-Path $ZipPath))) { New-Item -ItemType Directory -Force (Split-Path $ZipPath) | Out-Null }
    Compress-Archive -Path ($entries | ForEach-Object { $_.FullName }) -DestinationPath $ZipPath -Force
    return $true
}

function Prune-History([int]$Keep = 30) {
    $zips = @(Get-ChildItem $script:HistoryDir -Filter '*.zip' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($zips.Count -gt $Keep) { $zips | Select-Object -Skip $Keep | Remove-Item -Force }
}

function Describe-Folder([string]$Dir) {
    $files = @(Get-Entries $Dir | Where-Object { -not $_.PSIsContainer })
    if ($files.Count -eq 0) { return 'empty' }
    $newest = ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    $careers = @($files | Where-Object { $_.Name -like 'MyCAREER*' } | ForEach-Object { $_.Name })
    return ("{0} files, newest {1:yyyy-MM-dd HH:mm}, careers: {2}" -f $files.Count, $newest, $(if ($careers.Count) { $careers -join ' ' } else { 'none' }))
}

# ---------------------------------------------------------------- recognising Revival's saves

function Get-RevivalRecord([string]$Remote) {
    # Revival writes .revival_sync.json next to the Steam save folder after every upload or restore: the exact files
    # (name + sha256) of the set it last synced on this PC. Returns @{ name = HASH } or $null when there is none.
    if (-not $Remote) { return $null }
    $p = Join-Path (Split-Path $Remote) '.revival_sync.json'
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    try {
        $rec = @{}
        foreach ($f in (Get-Content -LiteralPath $p -Raw | ConvertFrom-Json).files) {
            if ($f.name -and $f.sha256) { $rec[[string]$f.name] = ([string]$f.sha256).ToUpper() }
        }
        if ($rec.Count -gt 0) { return $rec }
    } catch {}
    return $null
}

function Test-RevivalSet([string]$Dir, [hashtable]$Record) {
    # True when $Dir holds the set Revival last synced: every recorded file is there, byte for byte. Three small files
    # (CreatedPlayers, RosterDescriptions, UserDataTattoos) can be identical for both clients, so they never count alone.
    if (-not $Record -or $Record.Count -eq 0) { return $false }
    $sig = Get-Signature $Dir
    if ($sig.Count -eq 0 -or (Count-Identical $Record $sig) -ne $Record.Count) { return $false }
    return (@($Record.Keys | Where-Object { $_ -notin $script:SharedSaveFiles }).Count -gt 0)
}

function Get-SaveOwnerGuess([string]$Remote) {
    # What the Steam save folder holds, as far as that can be told without asking: 'Empty', 'Revival' or $null (ask).
    if (-not $Remote -or (Get-Entries $Remote).Count -eq 0) { return 'Empty' }
    if (Test-RevivalSet $Remote (Get-RevivalRecord $Remote)) { return 'Revival' }
    return $null
}

function Find-ParkedRevivalSet([string]$Remote) {
    # Looks through the "Unknown" sets parked by earlier switches for the one Revival last synced. Returns its folder or $null.
    $rec = Get-RevivalRecord $Remote
    if (-not $rec) { return $null }
    foreach ($d in (Get-ChildItem $script:ParkingRoot -Directory -Filter 'Unknown_*' -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
        $r = Join-Path $d.FullName 'remote'
        if (Test-RevivalSet $r $rec) { return $r }
    }
    return $null
}

function Repair-BlankRevivalFolder([string]$Remote) {
    # Version 2.2 could start Revival on an empty folder while its saves sat parked as "Unknown"; the game then made a
    # blank set. If the folder has no careers and that parked set is still there, offer to put it back.
    if (@(Get-Entries $Remote | Where-Object { $_.Name -like 'MyCAREER*' }).Count -gt 0) { return }
    $found = Find-ParkedRevivalSet $Remote
    if (-not $found -or @(Get-Entries $found | Where-Object { $_.Name -like 'MyCAREER*' }).Count -eq 0) { return }
    $desc = Describe-Folder $found
    Write-Log "The Steam save folder has no careers, but Revival's last synced saves are parked on this PC ($desc)." 'WARN'
    if (-not (& $script:AskYesNo "Revival's careers are missing from the Steam save folder, but the launcher still has them parked ($desc). Put them back before starting Revival?")) {
        Write-Log 'Left the Steam save folder as it is.' 'WARN'
        return
    }
    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $zip = Join-Path $script:HistoryDir "Revival-blank_$stamp.zip"
    if (Zip-Contents $Remote $zip) { Write-Log "Safety copy of the blank set: $(Split-Path $zip -Leaf)" }
    Reset-Folder $Remote
    Copy-Contents $found $Remote
    Write-Log "Put Revival's saves back in place ($((Get-Entries $Remote).Count) files)." 'OK'
}

# ---------------------------------------------------------------- Back2Back's post-game cloud save

function Test-Back2BackUploadDone {
    # Returns 'done', 'busy' or 'unknown'. Back2Back saves to its cloud right after the game closes.
    $logDir = Join-Path $env:LOCALAPPDATA 'BACK2BACK17\Support'
    $log = Get-ChildItem (Join-Path $logDir 'support-*.txt') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $log) { return 'done' }
    if (((Get-Date) - $log.LastWriteTime).TotalMinutes -gt 30) { return 'done' }
    $tail = Get-Content $log.FullName -Tail 60
    $closedLine = @($tail | Where-Object { $_ -match '^(\d\d):(\d\d):(\d\d)\s+GAME\s+game closed' }) | Select-Object -Last 1
    if (-not $closedLine) { return 'done' }
    $t = [datetime]::ParseExact($closedLine.Substring(0, 8), 'HH:mm:ss', $null)
    $closedAt = Get-Date -Hour $t.Hour -Minute $t.Minute -Second $t.Second
    if ($closedAt -gt (Get-Date).AddMinutes(1)) { $closedAt = $closedAt.AddDays(-1) }
    if (((Get-Date) - $closedAt).TotalMinutes -gt 10) { return 'done' }
    $sync = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Rebirth2K17\regions\*\accounts\*\cloud_sync.json') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($sync -and $sync.LastWriteTime -ge $closedAt.AddSeconds(-2)) { return 'done' }
    return 'busy'
}

function Wait-ForBack2BackUpload {
    if ((Test-Back2BackUploadDone) -eq 'done') { return }
    if ($script:NoWait) { Fail 'Back2Back is still saving to its cloud. Wait until its launcher says "Progress saved", then try again.' }
    $deadline = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $deadline) {
        Write-Log 'Waiting for Back2Back to finish saving to its cloud...'
        Start-Sleep -Seconds 5
        if ((Test-Back2BackUploadDone) -eq 'done') { Write-Log 'Back2Back has finished saving to its cloud.' 'OK'; return }
    }
    Write-Log 'Could not confirm that Back2Back finished its cloud save. Its launcher should say "Progress saved" first.' 'WARN'
    if (-not $script:Force) {
        if (-not (& $script:AskYesNo 'Continue anyway?')) { Fail 'Stopped. Wait until Back2Back shows "Progress saved", then try again.' }
    }
}

# ---------------------------------------------------------------- shortcuts, icon, exe

function New-DesktopShortcut([string]$Name, [string]$TargetPath, [string]$Arguments, [string]$IconPath, [string]$WorkDir) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut((Join-Path $desktop "$Name.lnk"))
    $lnk.TargetPath = $TargetPath
    $lnk.Arguments = $Arguments
    $lnk.WorkingDirectory = $WorkDir
    if ($IconPath -and (Test-Path $IconPath)) { $lnk.IconLocation = "$IconPath,0" }
    $lnk.Save()
}

function Remove-OldPlayShortcuts {
    # Versions up to 2.2 also put "Play Revival" / "Play Back2Back" on the desktop. The launcher window is the
    # one way in now, so take those away again. Only shortcuts that point at this tool are touched.
    $desktop = [Environment]::GetFolderPath('Desktop')
    $ws = New-Object -ComObject WScript.Shell
    foreach ($name in 'Play Revival', 'Play Back2Back') {
        $p = Join-Path $desktop "$name.lnk"
        if (-not (Test-Path -LiteralPath $p)) { continue }
        try {
            if (($ws.CreateShortcut($p)).Arguments -like '*NBA2K17-Switcher.ps1*') { Remove-Item -LiteralPath $p -Force; Write-Log "Removed the old `"$name`" desktop icon (the launcher window replaces it)." }
        } catch {}
    }
}

function New-AppIcon([string]$Path) {
    # Draws a simple basketball and writes a classic 64x64 32-bit icon (works for csc, shortcuts and WPF).
    Add-Type -AssemblyName System.Drawing
    $size = 64
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $orange = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 232, 112, 36))
    $g.FillEllipse($orange, 2, 2, $size - 4, $size - 4)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 48, 26, 16)), 3
    $g.DrawEllipse($pen, 2, 2, $size - 4, $size - 4)
    $g.DrawLine($pen, $size / 2, 2, $size / 2, $size - 2)
    $g.DrawLine($pen, 2, $size / 2, $size - 2, $size / 2)
    $g.DrawArc($pen, -26, 6, 54, 52, -62, 124)
    $g.DrawArc($pen, 36, 6, 54, 52, 118, 124)
    $g.Dispose()
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter $ms
    $rowMask = 8   # 64 pixels / 8 bits, already a multiple of 4
    $dibSize = 40 + ($size * $size * 4) + ($rowMask * $size)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)                       # ICONDIR
    $bw.Write([byte]$size); $bw.Write([byte]$size); $bw.Write([byte]0); $bw.Write([byte]0)  # entry: w, h, colors, reserved
    $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$dibSize); $bw.Write([uint32]22)
    $bw.Write([uint32]40); $bw.Write([int32]$size); $bw.Write([int32]($size * 2)); $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]0); $bw.Write([uint32]($size * $size * 4)); $bw.Write([int32]0); $bw.Write([int32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
    for ($y = $size - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $size; $x++) {
            $c = $bmp.GetPixel($x, $y)
            $bw.Write([byte]$c.B); $bw.Write([byte]$c.G); $bw.Write([byte]$c.R); $bw.Write([byte]$c.A)
        }
    }
    for ($y = $size - 1; $y -ge 0; $y--) {
        for ($bx = 0; $bx -lt $rowMask; $bx++) {
            $b = 0
            for ($bit = 0; $bit -lt 8; $bit++) { if ($bmp.GetPixel($bx * 8 + $bit, $y).A -lt 128) { $b = $b -bor (0x80 -shr $bit) } }
            $bw.Write([byte]$b)
        }
    }
    $bw.Flush()
    if (-not (Test-Path (Split-Path $Path))) { New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null }
    [System.IO.File]::WriteAllBytes($Path, $ms.ToArray())
    $bw.Close(); $bmp.Dispose()
}

function Test-SmartAppControlOn {
    # Windows 11's Smart App Control refuses to run unsigned programs such as our locally built exe.
    # (1 = on, 2 = evaluation, 0 = off). When it is on, the desktop icon opens the window through PowerShell instead.
    try { $v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -ErrorAction Stop).VerifiedAndReputablePolicyState; return ($v -eq 1) } catch { return $false }
}

function Get-LauncherShortcutTarget {
    # Returns @{ target; args; workdir } for a desktop shortcut that opens the launcher window.
    if ((Test-Path $script:ExePath) -and -not (Test-SmartAppControlOn)) { return @{ target = $script:ExePath; args = ''; workdir = $script:Root } }
    return @{ target = $script:PowerShellExe; args = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script:GuiScript`""; workdir = $script:Root }
}

function Build-LauncherExe {
    # Compiles the tiny "NBA 2K17 Launcher.exe" stub with the C# compiler that ships with Windows.
    $src = Join-Path $script:Root 'Launcher\NBA2K17Launcher.cs'
    if (-not (Test-Path $src)) { return $null }
    $csc = Get-ChildItem (Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4*\csc.exe'), (Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4*\csc.exe') -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $csc) { Write-Log 'No C# compiler on this PC; the desktop icon will open the launcher window directly instead.' 'WARN'; return $null }
    if (-not (Test-Path $script:IconPath)) { New-AppIcon $script:IconPath }
    if (Get-Process | Where-Object { $_.Path -eq $script:ExePath }) { Write-Log 'The launcher exe is open; close it to rebuild it.' 'WARN'; return $script:ExePath }
    $buildLog = Join-Path $script:AppDir 'build.log'
    $p = Start-Process $csc.FullName -ArgumentList @('/nologo', '/target:winexe', "/out:`"$script:ExePath`"", "/win32icon:`"$script:IconPath`"", '/reference:System.Windows.Forms.dll', "`"$src`"") -Wait -PassThru -NoNewWindow -RedirectStandardOutput $buildLog
    if ($p.ExitCode -eq 0 -and (Test-Path $script:ExePath)) { return $script:ExePath }
    Write-Log "Could not build the launcher exe (see data\build.log); the desktop icon will open the window directly instead." 'WARN'
    return $null
}

function Set-HighDpiFlagLikeRevival {
    # If Revival marked its game exe as DPI-aware (it does on high-DPI screens), do the same for Back2Back's copy.
    try {
        $key = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
        $r = Get-ClientGameFolder 'Revival'; $b = Get-ClientGameFolder 'Back2Back'
        if (-not $r -or -not $b -or ($r.TrimEnd('\') -ieq $b.TrimEnd('\'))) { return }
        $props = Get-ItemProperty $key -ErrorAction SilentlyContinue
        $rExe = Join-Path $r 'NBA2K17.exe'; $bExe = Join-Path $b 'NBA2K17.exe'
        $rVal = $props.PSObject.Properties | Where-Object { $_.Name -ieq $rExe } | Select-Object -First 1
        $bVal = $props.PSObject.Properties | Where-Object { $_.Name -ieq $bExe } | Select-Object -First 1
        if ($rVal -and -not $bVal) { New-ItemProperty -Path $key -Name $bExe -Value $rVal.Value -PropertyType String -Force | Out-Null; Write-Log "Copied Revival's display-scaling setting to Back2Back's game copy." }
    } catch {}
}

# ---------------------------------------------------------------- updates (GitHub Releases)

function Normalize-Version([string]$Text) {
    $t = ($Text -replace '^[vV]', '').Trim()
    $parts = @($t -split '\.' | Where-Object { $_ -match '^\d+$' })
    while ($parts.Count -lt 3) { $parts += '0' }
    try { return [version](($parts[0..2]) -join '.') } catch { return [version]'0.0.0' }
}

function Get-UpdateSource {
    # update.json next to the scripts: {"owner":"<github user>","repo":"<repository>"}
    if (-not (Test-Path $script:UpdateConfig)) { return $null }
    try { $c = Get-Content $script:UpdateConfig -Raw | ConvertFrom-Json } catch { return $null }
    if (-not $c.owner -or -not $c.repo -or $c.owner -like '*<*') { return $null }
    return @{ owner = $c.owner; repo = $c.repo; api = "https://api.github.com/repos/$($c.owner)/$($c.repo)/releases/latest"; page = "https://github.com/$($c.owner)/$($c.repo)/releases" }
}

function Get-UpdateInfo([int]$TimeoutSec = 8) {
    # Returns @{ configured; available; local; latest; url; notes; page; error }
    $r = @{ configured = $false; available = $false; local = $script:Version; latest = $null; url = $null; notes = ''; page = $null; error = $null }
    $src = Get-UpdateSource
    if (-not $src) { return $r }
    $r.configured = $true; $r.page = $src.page
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $rel = Invoke-RestMethod -Uri $src.api -Headers @{ 'User-Agent' = 'NBA2K17-Switcher'; 'Accept' = 'application/vnd.github+json' } -TimeoutSec $TimeoutSec
        $r.latest = ($rel.tag_name -replace '^[vV]', '')
        $asset = $rel.assets | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
        if ($asset) { $r.url = $asset.browser_download_url }
        $r.notes = "$($rel.name) $($rel.body)".Trim()
        $r.available = ((Normalize-Version $r.latest) -gt (Normalize-Version $script:Version)) -and [bool]$r.url
    } catch {
        $r.error = $_.Exception.Message
    }
    return $r
}

function Invoke-Update([string]$Url, [string]$Version) {
    # Downloads the release zip, unpacks it over this folder (data\ untouched) and rebuilds the exe if its source changed.
    if (-not $Url) { Fail 'No download link for the update.' }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("NBA2K17-Switcher-update-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force $tmp | Out-Null
    $zip = Join-Path $tmp 'update.zip'
    Write-Log "Downloading version $Version..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $zip -Headers @{ 'User-Agent' = 'NBA2K17-Switcher' } -TimeoutSec 60
    $unz = Join-Path $tmp 'unzipped'
    Expand-Archive -Path $zip -DestinationPath $unz -Force
    $core = Get-ChildItem $unz -Recurse -Filter 'Switcher.Core.ps1' | Select-Object -First 1
    if (-not $core) { Fail 'The downloaded zip does not look like the NBA 2K17 Switcher (no Switcher.Core.ps1 inside).' }
    $srcRoot = $core.DirectoryName
    $csBefore = $null; $csPath = Join-Path $script:Root 'Launcher\NBA2K17Launcher.cs'
    if (Test-Path $csPath) { $csBefore = (Get-FileHash -LiteralPath $csPath).Hash }
    $copied = 0
    foreach ($f in (Get-ChildItem -Recurse -File -Force $srcRoot)) {
        $rel = $f.FullName.Substring($srcRoot.Length).TrimStart('\')
        if ($rel -like 'data\*' -or $rel -ieq 'NBA 2K17 Launcher.exe') { continue }
        $dest = Join-Path $script:Root $rel
        $dd = Split-Path $dest
        if (-not (Test-Path $dd)) { New-Item -ItemType Directory -Force $dd | Out-Null }
        Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
        $copied++
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Updated to version $Version ($copied files)." 'OK'
    if ((Test-Path $csPath) -and ((Get-FileHash -LiteralPath $csPath).Hash -ne $csBefore)) {
        Write-Log 'The launcher exe source changed; rebuilding it...'
        [void](Build-LauncherExe)
    }
    return $copied
}

function New-ReleaseZip {
    # Zips this folder (without data\, the built exe and old zips) as ..\NBA2K17-Switcher-v<version>.zip for a GitHub release.
    $out = Join-Path (Split-Path $script:Root) ("NBA2K17-Switcher-v{0}.zip" -f $script:Version)
    $stage = Join-Path ([IO.Path]::GetTempPath()) ("NBA2K17-Switcher-zip-" + [Guid]::NewGuid().ToString('N'))
    $inner = Join-Path $stage 'NBA2K17-Switcher'
    New-Item -ItemType Directory -Force $inner | Out-Null
    foreach ($e in (Get-ChildItem -Force $script:Root)) {
        if ($e.Name -in 'data', '.git' -or $e.Name -ieq 'NBA 2K17 Launcher.exe' -or $e.Name -like '*.zip') { continue }
        Copy-Item -LiteralPath $e.FullName -Destination $inner -Recurse -Force
    }
    if (Test-Path $out) { Remove-Item $out -Force }
    Compress-Archive -Path $inner -DestinationPath $out -Force
    Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
    return $out
}

# ---------------------------------------------------------------- operations

function Get-StatusInfo {
    $info = @{}
    $info.version = $script:Version
    $info.steam = Get-SteamPath
    $info.remote = $null; if ($info.steam) { $info.remote = Find-RemoteFolder $info.steam }
    $info.remoteDesc = if ($info.remote) { Describe-Folder $info.remote } else { 'not found' }
    $info.revivalExe = Find-Launcher 'Revival'
    $info.back2backExe = Find-Launcher 'Back2Back'
    $info.revivalGame = Get-ClientGameFolder 'Revival'
    $info.back2backGame = Get-ClientGameFolder 'Back2Back'
    $info.shared = Test-SharedGameFolder
    $info.plan = Get-SplitPlan
    $info.state = Load-State
    $info.current = if ($info.state) { $info.state.current } else { 'not set up' }
    $info.lastSwitch = if ($info.state) { $info.state.lastSwitch } else { '' }
    $info.parkedRevival = Describe-Folder (Join-Path $script:ParkingRoot 'Revival\remote')
    $info.parkedBack2Back = Describe-Folder (Join-Path $script:ParkingRoot 'Back2Back\remote')
    $info.historyCount = @(Get-ChildItem $script:HistoryDir -Filter '*.zip' -ErrorAction SilentlyContinue).Count
    $info.gameRunning = [bool](Get-GameProcess)
    $info.launchers = @(Get-LauncherProcesses | ForEach-Object { $_.Name } | Sort-Object -Unique)
    $info.b2bUpload = Test-Back2BackUploadDone
    return $info
}

function Invoke-Setup([string]$CurrentClient, [string]$SeedRevival, [string]$SeedBack2Back, [switch]$NoShortcuts, [switch]$SkipSplitOffer) {
    Write-Log "NBA 2K17 Switcher $script:Version - setup"
    $steam = Get-SteamPath
    if (-not $steam) { Fail 'Steam was not found on this PC.' }
    $remote = Find-RemoteFolder $steam -CreateIfMissing
    if (-not $remote) { Fail "No NBA 2K17 save folder found under $steam\userdata and Steam is not signed in, so it could not be created. Sign in to Steam, then run setup again." }
    Write-Log "Steam save folder: $remote"
    if (-not $SkipSplitOffer) {
        $plan = Get-SplitPlan
        if ($plan.kind -eq 'shared') {
            Write-Log "Both clients use the same game folder ($($plan.source)). They overwrite each other's files there on every launch, so Back2Back needs its own copy of the game." 'WARN'
            if (& $script:AskYesNo 'Give Back2Back its own copy of the game now? (Both launchers and the game must be closed. 5-15 minutes.)') {
                try { Invoke-Split -Confirmed } catch { Write-Log ($_.Exception.Message -replace '^SWITCHER: ', '') 'WARN'; Write-Log 'Setup continues; run Split.cmd later or click "Split game folder" in the launcher.' 'WARN' }
            } else {
                Write-Log 'Skipped. The launcher keeps its tiles off until the split is done (Split.cmd, or "Split game folder" in the window).' 'WARN'
            }
        } elseif ($plan.kind -eq 'prepare') {
            Write-Log "Revival uses $($plan.source) and Back2Back is not set up yet. Back2Back should get its own copy of the game so the two never share a folder." 'WARN'
            if (& $script:AskYesNo "Prepare Back2Back's copy now ($($plan.target))? (5-15 minutes.)") {
                try { Invoke-Split -Confirmed } catch { Write-Log ($_.Exception.Message -replace '^SWITCHER: ', '') 'WARN' }
            } else {
                Write-Log 'Skipped. When you install Back2Back, either pick the original folder and run Split.cmd afterwards, or run Split.cmd first and pick the -Back2Back copy.' 'WARN'
            }
        }
    }
    $launchers = @{}
    foreach ($c in 'Revival', 'Back2Back') {
        $exe = Find-Launcher $c
        if ($exe) { Write-Log "$c launcher: $exe" } else { Write-Log "$c launcher not found. Install it, then run setup again (the other client still works)." 'WARN' }
        $launchers[$c] = $exe
    }
    foreach ($d in $script:AppDir, $script:ParkingRoot, $script:HistoryDir, (Join-Path $script:ParkingRoot 'Revival\remote'), (Join-Path $script:ParkingRoot 'Back2Back\remote')) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
    }
    if ($SeedRevival)   { if (-not (Test-Path $SeedRevival))   { Fail "SeedRevival folder not found: $SeedRevival" };   Reset-Folder (Join-Path $script:ParkingRoot 'Revival\remote');   Copy-Contents $SeedRevival   (Join-Path $script:ParkingRoot 'Revival\remote');   Write-Log "Parked Revival saves seeded from $SeedRevival" }
    if ($SeedBack2Back) { if (-not (Test-Path $SeedBack2Back)) { Fail "SeedBack2Back folder not found: $SeedBack2Back" }; Reset-Folder (Join-Path $script:ParkingRoot 'Back2Back\remote'); Copy-Contents $SeedBack2Back (Join-Path $script:ParkingRoot 'Back2Back\remote'); Write-Log "Parked Back2Back saves seeded from $SeedBack2Back" }

    $cur = $CurrentClient
    if (-not $cur) { $cur = 'Unknown' }
    if ((Get-Entries $remote).Count -eq 0) { $cur = 'Unknown'; Write-Log 'The Steam save folder is empty (nothing played yet), so there is nothing to park: each client fills it on its first launch.' }
    elseif ($cur -ne 'Revival' -and (Get-SaveOwnerGuess $remote) -eq 'Revival') {
        # Revival's own record settles it, whatever was answered: these are byte for byte the files it last synced here.
        Write-Log "The saves in the Steam folder are exactly the ones Revival last synced on this PC, so they are kept as Revival's." 'OK'
        $cur = 'Revival'
    }
    if ($cur -ne 'Unknown') {
        $slot = Join-Path $script:ParkingRoot "$cur\remote"
        if ((Get-Entries $remote).Count -gt 0) { Reset-Folder $slot; Copy-Contents $remote $slot; Write-Log "Took a copy of the current saves as $cur's parked set." }
    } else {
        Write-Log 'Current saves marked as unknown: the first switch parks them under parking\Unknown_<date> as a safety copy and starts the launched client on an empty folder.' 'WARN'
    }
    $state = @{ version = $script:Version; steamPath = $steam; remote = $remote; current = $cur; lastSwitch = (Get-Date).ToString('s'); setupAt = (Get-Date).ToString('s'); revivalExe = $launchers['Revival']; back2backExe = $launchers['Back2Back'] }
    Save-State $state
    Set-HighDpiFlagLikeRevival
    if (-not $NoShortcuts) {
        if (-not (Test-Path $script:IconPath)) { New-AppIcon $script:IconPath }
        if (Test-SmartAppControlOn) { Write-Log 'Smart App Control is on: Windows will not run the unsigned launcher exe, so the desktop icon opens the window through PowerShell instead.' 'WARN' }
        else { [void](Build-LauncherExe) }
        $t = Get-LauncherShortcutTarget
        New-DesktopShortcut 'NBA 2K17 Launcher' $t.target $t.args $script:IconPath $t.workdir
        Remove-OldPlayShortcuts
        $old = Join-Path ([Environment]::GetFolderPath('Desktop')) 'NBA2K17 Switcher Status.lnk'; if (Test-Path $old) { Remove-Item $old -Force }
        Write-Log 'Desktop icon created: "NBA 2K17 Launcher".' 'OK'
    }
    Write-Log "Setup done. Saves in place for: $cur" 'OK'
    if (Test-SharedGameFolder) {
        Write-Log "Both clients still use the same game folder ($(Get-ClientGameFolder 'Revival')). Run Split.cmd once (with both launchers closed) to give Back2Back its own copy." 'WARN'
    }
    return $state
}

function Invoke-Play([string]$Target) {
    # Returns a hashtable: @{ started = $true/$false; advice = '...' }
    $state = Load-State
    if (-not $state) { Fail 'Not set up yet. Run Install.cmd first.' }
    $remote = $state.remote
    if (-not (Test-Path $remote)) { Fail "The Steam save folder is missing: $remote" }
    if (Get-GameProcess) { Fail 'NBA 2K17 is still running. Quit the game first, then try again.' }
    $exeKey = @{ 'Revival' = 'revivalExe'; 'Back2Back' = 'back2backExe' }[$Target]
    $exe = $state[$exeKey]
    if (-not $exe -or -not (Test-Path $exe)) { $exe = Find-Launcher $Target }
    if (-not $exe) { Fail "$Target's launcher was not found. Install it, then run Install.cmd again." }
    $advice = if ($Target -eq 'Revival') { 'Press Play in Revival. If it asks Cloud or Local, pick the side you played most recently (one PC only: Local).' } else { 'Press Play in Back2Back. When you finish, quit the game and wait for "Progress saved" before switching.' }

    $current = $state.current
    if ($current -eq 'Unknown' -and (Get-SaveOwnerGuess $remote) -eq 'Revival') {
        Write-Log "The saves in the Steam folder are exactly the ones Revival last synced on this PC, so they are kept as Revival's." 'OK'
        $current = 'Revival'
    }
    if ($current -eq 'Revival' -and $Target -eq 'Revival') { Repair-BlankRevivalFolder $remote }
    if ($current -ne $Target) {
        $live = Get-Signature $remote
        if ($live.Count -gt 0 -and $current -ne 'Unknown') {
            $scores = @{}; $liveDistinct = Get-DistinctSignature $remote
            foreach ($c in 'Revival', 'Back2Back') { $scores[$c] = Count-Identical $liveDistinct (Get-DistinctSignature (Join-Path $script:ParkingRoot "$c\remote")) }
            if ($scores[$Target] -gt $scores[$current] -and $scores[$Target] -ge 3) {
                Write-Log "The folder looks like $Target's saves, but the switcher expected $current's. Did you copy files by hand?" 'WARN'
                if (-not $script:Force) {
                    $a = & $script:AskThree 'Whose saves are in the folder right now?' "$Target's (just start $Target)" "$current's (park them, then switch)"
                    switch ($a) {
                        'A' { $current = $Target }
                        'B' { }
                        default { Fail 'Cancelled. Nothing was changed.' }
                    }
                }
            }
        }
    }
    if ($current -eq $Target) {
        if ($state.current -ne $Target) { $state.current = $Target; Save-State $state }
        Write-Log "$Target's saves are already in place. Starting $Target." 'OK'
        Start-Process $exe
        return @{ started = $true; advice = $advice; switched = $false }
    }

    if ($current -eq 'Back2Back') { Wait-ForBack2BackUpload }

    $incoming = Join-Path $script:ParkingRoot "$Target\remote"
    $revivalHasNoCopy = $false
    if ($Target -eq 'Revival' -and (Get-Entries $incoming).Count -eq 0) {
        # Nothing parked for Revival. An "Unknown" set parked earlier may be its saves; otherwise there is no copy on this
        # PC, and Revival does not refill an empty folder when it believes this PC is already in sync with its cloud.
        $found = Find-ParkedRevivalSet $remote
        if ($found) {
            Copy-Contents $found $incoming
            Write-Log "Found Revival's last synced saves among the parked sets ($(Split-Path (Split-Path $found) -Leaf)); using them." 'OK'
        } elseif (Get-RevivalRecord $remote) {
            $revivalHasNoCopy = $true
            Write-Log "No copy of Revival's saves on this PC. Revival has synced here before, so it will probably not download them into an empty folder by itself." 'WARN'
            if (-not $script:Force) {
                if (-not (& $script:AskYesNo "There is no copy of Revival's saves on this PC, and Revival will probably NOT download them by itself (it thinks this PC is already up to date). The game may start with no careers. If it does: quit right away and do not press Play in Revival again, because that uploads the empty set over your cloud saves. Start Revival anyway?")) { Fail 'Cancelled. Nothing was changed.' }
            }
        }
    }

    $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $outgoingName = if ($current -eq 'Unknown') { "Unknown_$stamp" } else { $current }
    $live = Get-Signature $remote
    if ($live.Count -gt 0) {
        $zip = Join-Path $script:HistoryDir "$outgoingName`_$stamp.zip"
        if (Zip-Contents $remote $zip) { Write-Log "Safety copy of the outgoing saves: $(Split-Path $zip -Leaf)" }
        Move-Contents $remote (Join-Path $script:ParkingRoot "$outgoingName\remote")
        Write-Log "Parked $outgoingName's saves ($($live.Count) files)."
    } else {
        Write-Log 'The Steam save folder was empty; nothing to park.'
    }
    $n = (Get-Entries $incoming).Count
    if ($n -gt 0) {
        Copy-Contents $incoming $remote
        Write-Log "Put $Target's saves in place ($n files)." 'OK'
    } elseif ($revivalHasNoCopy) {
        Write-Log 'The folder is left empty. If Revival shows no careers, quit right away and do not press Play again: that would upload the empty set.' 'WARN'
        $advice = 'No copy of Revival''s saves on this PC. If the game shows no careers, quit right away and do NOT press Play again (that uploads the empty set).'
    } else {
        Write-Log "No parked saves for $Target yet. The folder is left empty so $Target can download its own cloud copy; if it asks, choose Cloud." 'WARN'
        $advice = "No parked saves for $Target yet: it should download its cloud copy. If it asks Cloud or Local, choose Cloud."
    }
    $state.current = $Target
    $state.lastSwitch = (Get-Date).ToString('s')
    Save-State $state
    Prune-History
    Write-Log "Starting $Target." 'OK'
    Start-Process $exe
    return @{ started = $true; advice = $advice; switched = $true }
}

function Get-SplitPlan {
    # What the folder situation needs: 'none' (separate already), 'shared' (both point at one folder),
    # 'prepare' (Revival known, Back2Back not set up yet), 'repoint' (a -Back2Back copy exists already), or 'wait'.
    $rev = Get-ClientGameFolder 'Revival'
    $b2b = Get-ClientGameFolder 'Back2Back'
    $plan = @{ kind = 'wait'; source = $rev; target = $null; back2back = $b2b; note = '' }
    if (-not $rev -and -not $b2b) { $plan.note = 'Neither client has a game folder yet. Install Revival (or Back2Back), point it at NBA2K17.exe, then run setup again.'; return $plan }
    if ($rev -and $b2b -and ($rev.TrimEnd('\') -ine $b2b.TrimEnd('\'))) { $plan.kind = 'none'; $plan.target = $b2b; return $plan }
    if (-not $rev) { $plan.note = "Back2Back uses $b2b. Install Revival and point it at that same folder; setup then gives Back2Back its own copy."; return $plan }
    $src = $rev.TrimEnd('\'); $dst = "$src-Back2Back"
    $plan.source = $src; $plan.target = $dst
    if ((Test-Path (Join-Path $dst 'NBA2K17.exe'))) { $plan.kind = 'repoint'; return $plan }   # copy exists; Back2Back just needs pointing at it
    if ($b2b) { $plan.kind = 'shared' } else { $plan.kind = 'prepare' }
    return $plan
}

function Invoke-Split([switch]$DryRun, [switch]$Confirmed, [string]$TestSource, [string]$TestTarget) {
    Write-Log "NBA 2K17 Switcher $script:Version - give Back2Back its own game folder"
    $plan = Get-SplitPlan
    if ($TestSource) { $plan = @{ kind = 'prepare'; source = $TestSource.TrimEnd('\'); target = $TestTarget; back2back = $null } }   # self-test on a scratch folder; never touches the clients
    if ($plan.kind -eq 'none') { Write-Log "Already split. Revival uses $($plan.source) and Back2Back uses $($plan.back2back). Nothing to do." 'OK'; return }
    if ($plan.kind -eq 'wait') { Fail $plan.note }
    $src = $plan.source
    $dst = $plan.target
    $b2bConfigured = [bool]$plan.back2back
    if (-not $TestSource -and ((Get-GameProcess) -or (Get-LauncherProcesses))) { Fail 'Close NBA 2K17, Revival and Back2Back first, then run Split again.' }
    if (-not (Test-Path (Join-Path $src 'NBA2K17.exe'))) { Fail "NBA2K17.exe not found in $src" }
    if ($plan.kind -eq 'repoint') {
        Write-Log "A Back2Back copy already exists at $dst; no copying needed." 'OK'
        if ($DryRun) { Write-Log 'Dry run: nothing changed.' 'WARN'; return }
        if ($b2bConfigured) { Set-Back2BackGameFolder $dst; Clean-RevivalFolder $src }
        else { Write-Log "When Back2Back asks for the game, pick NBA2K17.exe in $dst" 'OK' }
        return
    }
    if ((Test-Path $dst) -and ((Get-Entries $dst).Count -gt 0)) { Fail "$dst already exists and is not empty, but has no NBA2K17.exe. Remove or rename it first." }

    $revivalFiles = 'RV', 'dinput8_shim.ini', '.revival-*', 'revival_loader.log', 'icon.ico', 'NBA2K17PC_meta.*', 'SYNC.BIN', '*.zip', '*.rar', '*.7z'
    $revivalDirs = '.rebirth2k_backups', '_Redist'
    $b2bFiles = 'b2b17_arena_*.iff', 'rebirth_dinput8.ini'
    $b2bDirs = 'cdn', 'store', '.rebirth2k_backups'

    $all = Get-ChildItem -Recurse -File -Force $src
    $toCopy = $all | Where-Object { $f = $_; -not ($revivalFiles | Where-Object { $f.Name -like $_ }) -and -not ($revivalDirs | Where-Object { $f.FullName -like "$src\$_\*" }) }
    $bytes = ($toCopy | Measure-Object Length -Sum).Sum
    $free = (Get-PSDrive ($src.Substring(0, 1))).Free
    Write-Log ("Game folder: {0}" -f $src)
    Write-Log ("New copy:    {0}" -f $dst)
    Write-Log ("To copy:     {0:N1} GB in {1} files; free space {2:N1} GB" -f ($bytes / 1GB), @($toCopy).Count, ($free / 1GB))
    if ($free -lt ($bytes + 2GB)) { Fail 'Not enough free space on that drive for a second copy of the game.' }
    if ($DryRun) { Write-Log 'Dry run: nothing copied or changed.' 'WARN'; return }
    if (-not $script:Force -and -not $Confirmed) {
        if (-not (& $script:AskYesNo 'Copy the game now? This takes 5-15 minutes.')) { Fail 'Cancelled. Nothing was changed.' }
    }
    $log = Join-Path $script:AppDir 'split-robocopy.log'
    $rcArgs = @("`"$src`"", "`"$dst`"", '/E', '/COPY:DAT', '/DCOPY:T', '/MT:16', '/R:2', '/W:2', '/NFL', '/NDL', '/NP', '/XJ', "`"/LOG:$log`"", '/XF') + $revivalFiles + @('/XD') + $revivalDirs
    Write-Log 'Copying... (details in data\split-robocopy.log)'
    $p = Start-Process robocopy -ArgumentList $rcArgs -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ge 8) { Fail "The copy reported errors (robocopy code $($p.ExitCode)). See $log. Nothing else was changed." }
    $exeSrc = Get-Item (Join-Path $src 'NBA2K17.exe'); $exeDst = Get-Item (Join-Path $dst 'NBA2K17.exe')
    if ($exeSrc.Length -ne $exeDst.Length) { Fail 'The copied NBA2K17.exe does not match the original. Stopping before changing any settings.' }
    Write-Log "Copy finished: $dst" 'OK'

    if ($b2bConfigured) {
        Set-Back2BackGameFolder $dst
        Clean-RevivalFolder $src
        Write-Log 'Two things to do by hand now:'
        Write-Log '  1. Open Back2Back > Settings: "Your game" should show the new -Back2Back folder. Press FIX OTHER CLIENT CONFLICT (Steam restarts), then QUICK CHECK. Set Window Mode to Fullscreen if the picture looks soft.'
        Write-Log '  2. Start each client once. Each registers its own Steam shortcut (Steam restarts once per client); if Windows asks to allow the game through the firewall, click Allow.'
    } else {
        Write-Log "Back2Back's copy is ready. When you install Back2Back and it asks for the game, pick NBA2K17.exe in $dst" 'OK'
        Write-Log 'Then click "Re-run setup" (or run Install.cmd again) so the launcher picks Back2Back up.'
    }
}

function Set-Back2BackGameFolder([string]$Folder) {
    $cfg = Join-Path $env:LOCALAPPDATA 'Rebirth2K17\config.json'
    $h = @{}
    if (Test-Path $cfg) { $json = Get-Content $cfg -Raw | ConvertFrom-Json; foreach ($pp in $json.PSObject.Properties) { $h[$pp.Name] = $pp.Value }; Copy-Item $cfg "$cfg.before-split" -Force }
    $h['game_path'] = (Join-Path $Folder 'NBA2K17.exe')
    if (-not (Test-Path (Split-Path $cfg))) { New-Item -ItemType Directory -Force (Split-Path $cfg) | Out-Null }
    ($h | ConvertTo-Json -Compress) | Set-Content $cfg -Encoding UTF8
    Write-Log "Back2Back now points at $Folder\NBA2K17.exe" 'OK'
}

function Clean-RevivalFolder([string]$Src) {
    # Take Back2Back's files out of Revival's folder and put the originals back.
    foreach ($pat in 'b2b17_arena_*.iff', 'rebirth_dinput8.ini') { Get-ChildItem -Path $Src -Filter $pat -File -Force -ErrorAction SilentlyContinue | Remove-Item -Force }
    $bak = Get-ChildItem (Join-Path $Src '.rebirth2k_backups\native-setup') -Filter 'dinput8.dll.*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($bak) { Copy-Item $bak.FullName (Join-Path $Src 'dinput8.dll') -Force; Write-Log "Restored Revival's dinput8.dll from Back2Back's backup." }
    foreach ($d in 'cdn', 'store', '.rebirth2k_backups') { $dd = Join-Path $Src $d; if (Test-Path $dd) { Remove-Item $dd -Recurse -Force } }
    $k16 = Join-Path $env:LOCALAPPDATA 'Rebirth2K17\k16_park'
    foreach ($name in '0A', 'manifest') {
        $orig = Join-Path $k16 "$name.orig"; $cur = Join-Path $Src $name
        if ((Test-Path $orig) -and (Test-Path $cur)) {
            if ((Get-FileHash -LiteralPath $orig).Hash -ne (Get-FileHash -LiteralPath $cur).Hash) { Copy-Item $orig $cur -Force; Write-Log "Restored the original $name in Revival's folder." }
        }
    }
    Set-HighDpiFlagLikeRevival
    Write-Log "Revival's folder cleaned: $Src" 'OK'
}

function Get-SplitAdvice {
    return "Two things to do by hand after the split: in Back2Back open Settings, press FIX OTHER CLIENT CONFLICT (Steam restarts), then QUICK CHECK; and start each client once (Steam restarts once per client; if Windows asks to allow the game through the firewall, click Allow)."
}
