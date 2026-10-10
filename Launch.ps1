param([switch]$Restore)
$ErrorActionPreference = 'Stop'
try {
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + (Join-Path $PSScriptRoot 'Patch.ps1') + '" -Pause'
    if ($Restore) { $arguments += ' -Restore' }
    $process = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -Wait -PassThru
    exit $process.ExitCode
} catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
