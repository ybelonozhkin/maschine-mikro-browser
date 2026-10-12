param(
    [string]$Target = 'C:\Program Files\Native Instruments\Maschine 3\Maschine 3.exe',
    [switch]$Restore,
    [switch]$Check,
    [switch]$Pause
)
$ErrorActionPreference = 'Stop'
function Get-Hash([byte[]]$Bytes) {
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}
function Read-Lua([string]$Name) {
    return [IO.File]::ReadAllText((Join-Path $PSScriptRoot ('patches\' + $Name)), [Text.Encoding]::UTF8).Replace("`r`n","`n")
}
function Compact-Lua([string]$Text) {
    return (($Text -split "`n" | Where-Object { $_.Trim() -and -not $_.TrimStart().StartsWith('--') } | ForEach-Object { $_.Trim() }) -join "`n") + "`n"
}
function Replace-Once([string]$Text,[string]$Before,[string]$After) {
    if (($Text.Split([string[]]@($Before),[StringSplitOptions]::None).Length - 1) -ne 1) { throw 'Unexpected source layout. No files changed.' }
    return $Text.Replace($Before,$After)
}
function Test-Runtime([bool]$Installed) {
    $directory = if ($Installed) { $script:runtimeDirectory } else { Join-Path $PSScriptRoot 'runtime' }
    foreach ($entry in $config.runtime_files.PSObject.Properties) {
        if ($entry.Name -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Invalid runtime filename.' }
        $path = Join-Path $directory $entry.Name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.Value) {
            throw ('Runtime file missing or changed: ' + $path)
        }
    }
}
function Install-Runtime {
    Test-Runtime $false
    New-Item -ItemType Directory -Path $script:runtimeDirectory -Force | Out-Null
    foreach ($entry in $config.runtime_files.PSObject.Properties) {
        Copy-Item -LiteralPath (Join-Path (Join-Path $PSScriptRoot 'runtime') $entry.Name) -Destination (Join-Path $script:runtimeDirectory $entry.Name) -Force
    }
    Test-Runtime $true
}
try {
    if ($Restore -and $Check) { throw 'Use either -Restore or -Check, not both.' }
    $Target = [IO.Path]::GetFullPath($Target)
    $backup = $Target + '.browser-original-3.7.1.bak'
    $config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'patches\compatibility.json') -Raw | ConvertFrom-Json
    $script:runtimeDirectory = Join-Path $env:PROGRAMDATA ('MaschineMikroBrowser\' + $config.version)
    [byte[]]$bytes = [IO.File]::ReadAllBytes($Target)
    $currentBytes = $bytes
    $hash = Get-Hash $bytes
    if ($Check) {
        if ($hash -eq $config.original_sha256) { Write-Host 'Supported original Maschine 3.7.1: ready to install.' -ForegroundColor Green }
        elseif ($hash -eq $config.patched_sha256) { Test-Runtime $true; Write-Host 'All Mikro browser patches are installed.' -ForegroundColor Green }
        elseif ($hash -in $config.previous_sha256) { Write-Host 'Supported previous patch: ready to upgrade to 0.3.0.' -ForegroundColor Green }
        else { throw 'Unsupported or modified EXE. This release supports one verified Maschine 3.7.1 x64 build.' }
        exit 0
    }
    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        ($_.ProcessName -eq 'Maschine 3' -or $_.ProcessName -eq 'Maschine3') -and -not $_.HasExited
    })
    if ($running.Count) { throw ('Close Maschine: ' + (($running | ForEach-Object { $_.ProcessName + ' (PID ' + $_.Id + ')' }) -join ', ')) }
    if ($Restore) {
        if ($hash -ne $config.patched_sha256 -and $hash -notin $config.previous_sha256) { throw 'Installed EXE does not match a supported patch; refusing to overwrite it.' }
        $original = [IO.File]::ReadAllBytes($backup)
        if ((Get-Hash $original) -ne $config.original_sha256) { throw 'Original backup verification failed.' }
        $handle = [IO.File]::Open($Target,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { $handle.Write($original,0,$original.Length); $handle.Flush() } finally { $handle.Dispose() }
        if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.original_sha256) { throw 'Restore verification failed.' }
        Write-Host 'Original Maschine restored.' -ForegroundColor Green
        exit 0
    }
    if ($hash -eq $config.patched_sha256) { Install-Runtime; Write-Host 'All patches are already installed.' -ForegroundColor Green; exit 0 }
    if ($hash -in $config.previous_sha256) {
        $bytes = [IO.File]::ReadAllBytes($backup)
        if ((Get-Hash $bytes) -ne $config.original_sha256) { throw 'Upgrade requires the verified original backup. No files changed.' }
        $hash = Get-Hash $bytes
    }
    if ($hash -ne $config.original_sha256 -or $bytes.Length -ne $config.file_bytes) { throw 'Unsupported or modified EXE. No files changed.' }
    $modified = [byte[]]$bytes.Clone()
    foreach ($name in @('browser','controller','plugin','busy')) {
        $resource = $config.resources.$name
        $text = [Text.Encoding]::UTF8.GetString($bytes,[int]$resource.offset,[int]$resource.bytes).Replace("`r`r`n","`n").Replace("`r`n","`n")
        if ($name -eq 'browser') {
            $text = Compact-Lua $text
            $text = Replace-Once $text 'PageMikroMK3.onShow(self, Show)' "PageMikroMK3.onShow(self, Show)`nif not Show then`nLEDHelper.setLEDOnOff(NI.HW.LED_LEFT,false)`nLEDHelper.setLEDOnOff(NI.HW.LED_RIGHT,false)`nend"
            $text += (Read-Lua 'browser-navigation.lua').TrimEnd()
        } elseif ($name -eq 'controller') {
            $text = 'require "Scripts/Shared/Helpers/ModuleHelper"' + "`n" + (Compact-Lua $text)
            $text = Replace-Once $text 'self.SwitchPressed[SwitchId] = Pressed' "self.SwitchPressed[SwitchId] = Pressed`nself:captureChainAction(SwitchId,Pressed)"
            $text = Replace-Once $text 'function MaschineMikroMK3:onControllerTimer()' "function MaschineMikroMK3:onControllerTimer()`nself:runChainAction()"
            $text = Replace-Once $text "self:updateLEDs()`nend" "self:updateLEDs()`nself:updateChainNotice()`nend"
            $registration = 'self.PageManager:register(NI.HW.PAGE_BUSY, Folder .. "BusyPageMikroMK3", "BusyPageMikroMK3", true)'
            $text = Replace-Once $text $registration ($registration + "`n" + 'self.PageManager:register(NI.HW.PAGE_SAVE_DIALOG,Folder.."BusyPageMikroMK3","BusyPageMikroMK3",true)')
            $text = Replace-Once $text 'ControllerScriptInterface = MaschineMikroMK3()' ((Read-Lua 'chain-actions.lua') + "`n" + (Read-Lua 'save-dialog.lua') + "`nControllerScriptInterface = MaschineMikroMK3()")
            $text = $text.TrimEnd()
        } elseif ($name -eq 'plugin') {
            $text = (((($text -replace "`n$",'') -split "`n") | Where-Object { -not $_.TrimStart().StartsWith('--') }) -join "`n") + "`n"
            $pattern = 'function PluginPageMikroMK3:onWheelEvent\(Value\)\s*end'
            if ([regex]::Matches($text,$pattern).Count -ne 1) { throw 'Unexpected plugin source layout.' }
            $handler = (Read-Lua 'plugin-scroll.lua').TrimEnd()
            $text = [regex]::Replace($text,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{ param($match) return $handler })
            $text = (Compact-Lua $text) + (Compact-Lua (Read-Lua 'runtime-loader.lua'))
        } else {
            $text = Read-Lua 'dialog-page.lua'
        }
        $code = [Text.Encoding]::UTF8.GetBytes($text)
        if ($code.Length -gt $resource.bytes) { throw 'Patch does not fit resource. No files changed.' }
        [Array]::Copy($code,0,$modified,[int]$resource.offset,$code.Length)
        for ($index=$code.Length; $index -lt $resource.bytes; $index++) { $modified[[int]$resource.offset+$index]=32 }
    }
    if ((Get-Hash $modified) -ne $config.patched_sha256) { throw 'Generated patch differs from verified release. No files changed.' }
    # Hold an exclusive handle throughout backup and installation.
    $handle = [IO.File]::Open($Target,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
        # The file may have changed while the replacement was being built.
        $locked = New-Object byte[] $currentBytes.Length
        $read = 0
        while ($read -lt $locked.Length) {
            $count = $handle.Read($locked,$read,$locked.Length-$read)
            if ($count -eq 0) { throw 'Target size changed. No files written.' }
            $read += $count
        }
        if ($handle.Length -ne $currentBytes.Length -or (Get-Hash $locked) -ne (Get-Hash $currentBytes)) {
            throw 'Target changed during preparation. No files written.'
        }
        $handle.Position = 0
        if (Test-Path -LiteralPath $backup) {
            if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.original_sha256) { throw 'Existing backup differs from the original. No files changed.' }
        } else {
            [IO.File]::WriteAllBytes($backup,$bytes)
            if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.original_sha256) {
                throw 'New backup verification failed. Target was not changed.'
            }
        }
        Install-Runtime
        try { $handle.Write($modified,0,$modified.Length); $handle.Flush() }
        catch { $handle.Position=0; $handle.Write($currentBytes,0,$currentBytes.Length); $handle.Flush(); throw }
    } finally { $handle.Dispose() }
    if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.patched_sha256) { throw 'Installed file verification failed; original backup is available.' }
    Write-Host 'All Mikro browser patches installed.' -ForegroundColor Green
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { if ($Pause) { Read-Host 'Press Enter to close' } }
