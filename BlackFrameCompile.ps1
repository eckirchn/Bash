#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:05 AM MST
BlackFrameCompile.ps1 - Windows companion to BlackFrameCompile.

One continuous range, from the earliest preview start to the latest stop.
The bash script is for the Xeon E5-2680. This file is for Windows PowerShell.
The Dell OptiPlex (i7-4770 + Quadro P2000) takes NVENC when the probe opens.

  .\BlackFrameCompile.ps1 h264
  .\BlackFrameCompile.ps1 h265 .\MyClip

If Windows blocks the script:

  powershell -ExecutionPolicy Bypass -File .\BlackFrameCompile.ps1 h264 .\MyClip
#>

param(
    [Parameter(Position = 0)]
    [string]$Codec,
    [Parameter(Position = 1)]
    [string]$WorkDirectory
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

if ([string]::IsNullOrWhiteSpace($Codec)) {
    Write-Host 'Usage: .\BlackFrameCompile.ps1 h264|h265 [work-directory]' -ForegroundColor Red
    exit 1
}

. "$PSScriptRoot\BlackFrameEncode.ps1"
Invoke-BlackFrameCompile -Codec $Codec -WorkDirectory $WorkDirectory -Mode continuous
