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
try {
    $Target = [IO.Path]::GetFullPath($Target)
    $backup = $Target + '.browser-original-3.7.1.bak'
    $config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'patches\compatibility.json') -Raw | ConvertFrom-Json
    [byte[]]$bytes = [IO.File]::ReadAllBytes($Target)
    $hash = Get-Hash $bytes
    if ($Check) {
        if ($hash -eq $config.original_sha256) { Write-Host 'Supported original Maschine 3.7.1: ready to install.' -ForegroundColor Green }
        elseif ($hash -eq $config.patched_sha256) { Write-Host 'All Mikro browser patches are installed.' -ForegroundColor Green }
        else { throw 'Unsupported or modified EXE. This release supports one verified Maschine 3.7.1 x64 build.' }
        exit 0
    }
    $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        ($_.ProcessName -eq 'Maschine 3' -or $_.ProcessName -eq 'Maschine3') -and -not $_.HasExited
    })
    if ($running.Count) { throw ('Close Maschine: ' + (($running | ForEach-Object { $_.ProcessName + ' (PID ' + $_.Id + ')' }) -join ', ')) }
    if ($Restore) {
        if ($hash -ne $config.patched_sha256) { throw 'Installed EXE does not match this patch; refusing to overwrite it.' }
        $original = [IO.File]::ReadAllBytes($backup)
        if ((Get-Hash $original) -ne $config.original_sha256) { throw 'Original backup verification failed.' }
        $handle = [IO.File]::Open($Target,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { $handle.Write($original,0,$original.Length); $handle.Flush() } finally { $handle.Dispose() }
        if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.original_sha256) { throw 'Restore verification failed.' }
        Write-Host 'Original Maschine restored.' -ForegroundColor Green
        exit 0
    }
    if ($hash -eq $config.patched_sha256) { Write-Host 'All patches are already installed.' -ForegroundColor Green; exit 0 }
    if ($hash -ne $config.original_sha256 -or $bytes.Length -ne $config.file_bytes) { throw 'Unsupported or modified EXE. No files changed.' }
    $modified = [byte[]]$bytes.Clone()
    foreach ($name in @('browser','controller','plugin')) {
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
            $text = Replace-Once $text 'ControllerScriptInterface = MaschineMikroMK3()' ((Read-Lua 'chain-actions.lua') + "`nControllerScriptInterface = MaschineMikroMK3()")
            $text = $text.TrimEnd()
        } else {
            $text = (((($text -replace "`n$",'') -split "`n") | Where-Object { -not $_.TrimStart().StartsWith('--') }) -join "`n") + "`n"
            $pattern = 'function PluginPageMikroMK3:onWheelEvent\(Value\)\s*end'
            if ([regex]::Matches($text,$pattern).Count -ne 1) { throw 'Unexpected plugin source layout.' }
            $handler = (Read-Lua 'plugin-scroll.lua').TrimEnd()
            $text = [regex]::Replace($text,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{ param($match) return $handler })
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
        if (Test-Path -LiteralPath $backup) {
            if ((Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.original_sha256) { throw 'Existing backup differs from the original. No files changed.' }
        } else { [IO.File]::WriteAllBytes($backup,$bytes) }
        try { $handle.Write($modified,0,$modified.Length); $handle.Flush() }
        catch { $handle.Position=0; $handle.Write($bytes,0,$bytes.Length); $handle.Flush(); throw }
    } finally { $handle.Dispose() }
    if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $config.patched_sha256) { throw 'Installed file verification failed; original backup is available.' }
    Write-Host 'All Mikro browser patches installed.' -ForegroundColor Green
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
finally { if ($Pause) { Read-Host 'Press Enter to close' } }
