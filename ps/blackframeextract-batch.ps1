#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:26 AM MST
PowerShell clone of blackframeextract-batch.
The bash script is unchanged.

Runs blackframeextract.ps1 on every source .mp4 in the current directory.
Finished compiles (*.h264.mp4, *.h265.mp4) and preview clips are skipped.
#>

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$extract = Join-Path $PSScriptRoot 'blackframeextract.ps1'
if (-not (Test-Path -LiteralPath $extract)) {
    $cmd = Get-Command blackframeextract.ps1 -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host 'blackframeextract.ps1 is not on PATH.' -ForegroundColor Red
        exit 1
    }
    $extract = $cmd.Source
}

Get-ChildItem -File -Filter '*.mp4' | ForEach-Object {
    $name = $_.Name
    if ($name -like '*.h264.mp4' -or $name -like '*.h265.mp4') { return }
    if ($name -like 'LQ_Clip*.mp4') { return }
    Write-Host "=== Processing: $name ==="
    & $extract $_.FullName
}
