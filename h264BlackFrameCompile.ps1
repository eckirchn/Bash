#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:05 AM MST
h264BlackFrameCompile.ps1 - Windows companion to h264BlackFrameCompile.

The bash script is for the Xeon E5-2680 (Linux, no GPU).
This file is for Windows PowerShell. The Dell OptiPlex (i7-4770, 4c/8t,
Quadro P2000) takes NVENC when a one-frame probe opens h264_nvenc.
Otherwise the encode flags stay libx264 slow, tune film, CRF 18.

  .\h264BlackFrameCompile.ps1
  .\h264BlackFrameCompile.ps1 .\MyClip

If Windows blocks the script:

  powershell -ExecutionPolicy Bypass -File .\h264BlackFrameCompile.ps1 .\MyClip
#>

param(
    [Parameter(Position = 0)]
    [string]$WorkDirectory
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
. "$PSScriptRoot\BlackFrameEncode.ps1"
Invoke-BlackFrameCompile -Codec h264 -WorkDirectory $WorkDirectory -Mode clips
