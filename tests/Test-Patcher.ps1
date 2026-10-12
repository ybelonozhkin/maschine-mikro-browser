param([Parameter(Mandatory=$true)][string]$OriginalExe,[string]$PreviousExe,[string]$WorkDirectory)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$config=Get-Content -LiteralPath (Join-Path $root 'patches\compatibility.json') -Raw | ConvertFrom-Json
function Hash([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
if((Hash $OriginalExe) -ne $config.original_sha256){throw 'Supply the supported original EXE.'}
if(-not $WorkDirectory){$WorkDirectory=Join-Path ([IO.Path]::GetTempPath()) ('maschine-patch-test-'+[Guid]::NewGuid().ToString('N'))}
$WorkDirectory=[IO.Path]::GetFullPath($WorkDirectory)
if(Test-Path -LiteralPath $WorkDirectory){throw 'WorkDirectory must be a new directory.'}
New-Item -ItemType Directory -Path $WorkDirectory | Out-Null
$testFile=Join-Path $WorkDirectory 'Maschine-test.exe'
$backup=$testFile+'.browser-original-3.7.1.bak'
# Give child patcher processes an isolated runtime installation directory.
$env:PROGRAMDATA=Join-Path $WorkDirectory 'ProgramData'
Copy-Item -LiteralPath $OriginalExe -Destination $testFile
function Invoke-Patch([string[]]$Flags,[bool]$Fail=$false){
 & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'Patch.ps1') -Target $testFile @Flags
 if($Fail){if($LASTEXITCODE -eq 0){throw 'Expected rejection.'}}
 elseif($LASTEXITCODE -ne 0){throw 'Patch command failed.'}
}
Invoke-Patch @('-Check')
Invoke-Patch @()
if((Hash $testFile) -ne $config.patched_sha256 -or (Hash $backup) -ne $config.original_sha256){throw 'Install or backup hash mismatch.'}
Invoke-Patch @('-Check')
Invoke-Patch @()
$runtimeFile=Join-Path $env:PROGRAMDATA ('MaschineMikroBrowser\'+$config.version+'\runtime.lua')
[IO.File]::WriteAllText($runtimeFile,'damaged runtime')
Invoke-Patch @('-Check') $true
Invoke-Patch @()
Invoke-Patch @('-Check')
if((Hash $runtimeFile) -ne $config.runtime_files.'runtime.lua'){throw 'Runtime repair mismatch.'}
Invoke-Patch @('-Restore')
if((Hash $testFile) -ne $config.original_sha256){throw 'Restore mismatch.'}
if($PreviousExe){
 if((Hash $PreviousExe) -notin $config.previous_sha256){throw 'PreviousExe is not a supported upgrade source.'}
 Copy-Item -LiteralPath $PreviousExe -Destination $testFile -Force
 Invoke-Patch @('-Check');Invoke-Patch @()
 if((Hash $testFile) -ne $config.patched_sha256){throw 'Upgrade mismatch.'}
 Invoke-Patch @('-Restore')
}
[IO.File]::WriteAllText($backup,'invalid backup')
Invoke-Patch @() $true
if((Hash $testFile) -ne $config.original_sha256){throw 'Rejected backup changed target.'}
Copy-Item -LiteralPath $OriginalExe -Destination $backup -Force
[IO.File]::WriteAllText($testFile,'unsupported executable')
$before=Hash $testFile
Invoke-Patch @() $true
if((Hash $testFile) -ne $before){throw 'Unsupported target was changed.'}
Write-Host ('Tests passed. Test copies retained in '+$WorkDirectory) -ForegroundColor Green
