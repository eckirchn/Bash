#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:05 AM MST
h265BlackFrameCompile.ps1 - Windows companion to h265BlackFrameCompile.

The bash script is for the Xeon E5-2680 (Linux, no GPU).
This file is for Windows PowerShell. The Dell OptiPlex (i7-4770, 4c/8t,
Quadro P2000) takes NVENC when a one-frame probe opens hevc_nvenc,
including 10-bit Main10. Otherwise the encode flags stay libx265 medium,
CRF 20, main10.

  .\h265BlackFrameCompile.ps1
  .\h265BlackFrameCompile.ps1 .\MyClip

If Windows blocks the script:

  powershell -ExecutionPolicy Bypass -File .\h265BlackFrameCompile.ps1 .\MyClip
#>

param(
    [Parameter(Position = 0)]
    [string]$WorkDirectory
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
. "$PSScriptRoot\BlackFrameEncode.ps1"
Invoke-BlackFrameCompile -Codec h265 -WorkDirectory $WorkDirectory -Mode clips
