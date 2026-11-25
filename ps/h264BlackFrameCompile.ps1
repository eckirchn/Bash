#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:26 AM MST
PowerShell clone of h264BlackFrameCompile.
The bash script is unchanged. This file runs the same encoder test and the same flags.

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

$script:PSNativeCommandUseErrorActionPreference = $false

function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor White }
function Write-Good([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Bad([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Accent([string]$Message) { Write-Host $Message -ForegroundColor Cyan }

function Stop-BlackFrame([string]$Message) {
    Write-Bad $Message
    exit 1
}

function Format-Seconds([decimal]$Value) {
    return $Value.ToString('0.################', [Globalization.CultureInfo]::InvariantCulture)
}

function Assert-EncodeTool([string]$Name) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        return
    }
    Write-Bad "missing: $Name"
    if ($Name -eq 'ffmpeg' -or $Name -eq 'ffprobe') {
        Write-Warn "Put ffmpeg.exe and ffprobe.exe in $env:USERPROFILE\bin and add that folder to the user PATH."
    }
    exit 1
}

function Get-CpuPercent {
    $counter = '\Processor(_Total)\% Processor Time'
    try {
        $null = Get-Counter -Counter $counter -ErrorAction Stop
        Start-Sleep -Seconds 1
        $value = (Get-Counter -Counter $counter -ErrorAction Stop).CounterSamples[0].CookedValue
        return [int][Math]::Round($value)
    } catch {
        $loads = @(Get-CimInstance -ClassName Win32_Processor |
            Select-Object -ExpandProperty LoadPercentage)
        Start-Sleep -Seconds 1
        if ($loads.Count -eq 0) {
            return 0
        }
        $avg = ($loads | Measure-Object -Average).Average
        if ($null -eq $avg) {
            return 0
        }
        return [int][Math]::Round($avg)
    }
}

function Wait-ForCpu {
    $limit = 80
    $need = 10
    $under = 0
    Write-Warn "Waiting until CPU stays under $limit% for $need seconds."
    while ($under -lt $need) {
        $pct = Get-CpuPercent
        if ($pct -lt $limit) {
            $under++
        } else {
            $under = 0
        }
        Write-Host ("`rCPU {0,3}% - under {1}% for {2} of {3} seconds   " -f $pct, $limit, $under, $need) -ForegroundColor Yellow -NoNewline
    }
    Write-Host ("`rCPU stayed under {0}% for {1} seconds. Starting.      " -f $limit, $need) -ForegroundColor Green
}

function Test-EncoderListed([string]$Name) {
    $list = & ffmpeg -hide_banner -encoders 2>$null
    if (-not $list) {
        return $false
    }
    $text = @($list) -join "`n"
    $pattern = '(?m)(^|\s)' + [regex]::Escape($Name) + '(\s|$)'
    return [bool]($text | Select-String -Pattern $pattern -Quiet)
}

function Test-NvencProbe([string[]]$EncArgs) {
    $ff = @(
        '-nostdin', '-hide_banner', '-loglevel', 'error',
        '-f', 'lavfi', '-i', 'color=c=black:s=256x256:r=24:d=0.05'
    ) + $EncArgs + @('-frames:v', '1', '-f', 'null', '-')
    & ffmpeg @ff *> $null
    return $LASTEXITCODE -eq 0
}

function Get-SourceCodec([string]$Path) {
    $out = & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 -- $Path 2>$null
    if (-not $out) {
        return ''
    }
    $line = @($out)[0]
    if ($null -eq $line) {
        return ''
    }
    return (($line.ToString() -replace "`r", '').Trim())
}

function Test-NvdecOk([string]$CodecName) {
    return $CodecName -in @('h264', 'hevc', 'mpeg2video', 'mpeg4', 'vc1', 'vp8', 'vp9')
}

function Find-SourceVideo([string]$Dir) {
    $stem = [IO.Path]::GetFileName($Dir)
    if ($stem.EndsWith('_work')) {
        $stem = $stem.Substring(0, $stem.Length - 5)
    }
    foreach ($ext in @('mp4', 'mkv', 'm4v', 'mov', 'ts', 'avi', 'mpg', 'mpeg')) {
        $candidate = Join-Path $Dir ($stem + '.' + $ext)
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).ProviderPath
        }
    }
    $exts = @('.mp4', '.mkv', '.m4v', '.mov', '.ts', '.avi', '.mpg', '.mpeg')
    $found = @(Get-ChildItem -LiteralPath $Dir -File | Where-Object {
        $exts -contains $_.Extension.ToLowerInvariant() -and
        $_.Name -notlike '*.clean.*' -and
        $_.Name -notlike '*.h264.mp4' -and
        $_.Name -notlike '*.h265.mp4'
    })
    if ($found.Count -eq 1) {
        return $found[0].FullName
    }
    if ($found.Count -eq 0) {
        Stop-BlackFrame "No source video in $Dir"
    }
    Stop-BlackFrame "More than one source video in $Dir; use a folder named after the source"
}

function Get-ClipRows([string]$LqDir) {
    $rows = New-Object System.Collections.Generic.List[object]
    $files = @(Get-ChildItem -LiteralPath $LqDir -File -Filter 'LQ_Clip*.mp4' -ErrorAction SilentlyContinue)
    foreach ($f in $files) {
        if ($f.BaseName -match '^LQ_Clip([0-9]+)_([0-9]+\.[0-9]+)-([0-9]+\.[0-9]+)$') {
            $rows.Add([pscustomobject]@{
                Id    = [int]$Matches[1]
                Start = [decimal]::Parse($Matches[2], [Globalization.CultureInfo]::InvariantCulture)
                Stop  = [decimal]::Parse($Matches[3], [Globalization.CultureInfo]::InvariantCulture)
            })
        } else {
            Write-Warn "skip (bad name): $($f.Name)"
        }
    }
    return $rows
}

function Invoke-TryEncode {
    param(
        [string]$OutFile,
        [ValidateSet('hw', 'sw')]
        [string]$Mode,
        [string[]]$InputArgs
    )
    $ff = @('-nostdin', '-hide_banner', '-stats', '-loglevel', 'error')
    if ($Mode -eq 'hw') {
        $ff += @('-hwaccel', 'cuda', '-hwaccel_output_format', 'cuda')
    }
    $ff += $InputArgs
    $ff += @('-threads', '0', '-map', '0:v:0', '-map', '0:a?')
    $ff += $script:VCodec
    $ff += @(
        '-colorspace', 'bt709', '-color_primaries', 'bt709', '-color_trc', 'bt709', '-color_range', 'tv',
        '-c:a', 'copy',
        '-avoid_negative_ts', 'make_zero',
        '-movflags', '+faststart',
        '-y', $OutFile
    )
    & ffmpeg @ff
    return $LASTEXITCODE -eq 0
}

function Invoke-RunEncode {
    param(
        [string]$OutFile,
        [string[]]$InputArgs,
        [string]$FailLabel
    )
    if ($script:UseHwaccel) {
        if (Invoke-TryEncode -OutFile $OutFile -Mode hw -InputArgs $InputArgs) {
            return
        }
        Write-Warn "Hardware decode failed on $FailLabel. Retrying with software decode."
        $script:UseHwaccel = $false
        if (Invoke-TryEncode -OutFile $OutFile -Mode sw -InputArgs $InputArgs) {
            return
        }
    } elseif (Invoke-TryEncode -OutFile $OutFile -Mode sw -InputArgs $InputArgs) {
        return
    }
    if ($script:UseNvenc) {
        Write-Warn "NVENC failed on $FailLabel. Falling back to software for this clip and the rest."
        $script:UseNvenc = $false
        $script:VCodec = $script:VCodecSw
        if (Invoke-TryEncode -OutFile $OutFile -Mode sw -InputArgs $InputArgs) {
            return
        }
    }
    Stop-BlackFrame "encode failed: $OutFile"
}

function ConvertTo-ConcatLine([string]$Path) {
    $p = $Path.Replace('\', '/')
    $p = $p.Replace("'", "'\''")
    return "file '$p'"
}

function Select-Encoder {
    param(
        [string]$NvName,
        [string]$SwName,
        [string[]]$SwArgs,
        [string[]]$NvP7,
        [string[]]$NvHq,
        [string]$LabelSw,
        [string]$LabelP7,
        [string]$LabelHq
    )
    $script:UseNvenc = $false
    $script:UseHwaccel = $false
    $script:Label = $LabelSw
    $script:VCodecSw = $SwArgs
    $script:VCodec = $SwArgs

    $script:GpuSeen = $false
    $smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($smi) {
        & nvidia-smi -L *> $null
        if ($LASTEXITCODE -eq 0) {
            $script:GpuSeen = $true
        }
    }
    $smiInstalled = [bool]$smi

    if ((Test-EncoderListed $NvName) -and ($script:GpuSeen -or -not $smiInstalled)) {
        if (Test-NvencProbe $NvP7) {
            $script:UseNvenc = $true
            $script:VCodec = $NvP7
            $script:Label = $LabelP7
        } elseif (Test-NvencProbe $NvHq) {
            $script:UseNvenc = $true
            $script:VCodec = $NvHq
            $script:Label = $LabelHq
            Write-Warn 'NVENC preset p7 was rejected. Using preset hq.'
        } elseif ($script:GpuSeen) {
            Write-Warn "NVENC probe failed. Using $SwName."
        }
    }

    if ($script:UseNvenc -and (Test-NvdecOk (Get-SourceCodec $script:Source))) {
        $script:UseHwaccel = $true
        $script:Label = "$($script:Label), CUDA decode"
    } elseif ($script:UseNvenc) {
        $script:Label = "$($script:Label), software decode"
    }
}

function Invoke-BlackFrameCompile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Codec,
        [string]$WorkDirectory,
        [Parameter(Mandatory = $true)]
        [ValidateSet('clips', 'continuous')]
        [string]$Mode
    )

    $ErrorActionPreference = 'Stop'
    $script:PSNativeCommandUseErrorActionPreference = $false

    if ($Codec -ne 'h264' -and $Codec -ne 'h265') {
        Stop-BlackFrame "First argument must be h264 or h265 (got: $Codec)"
    }

    Assert-EncodeTool 'ffmpeg'
    Assert-EncodeTool 'ffprobe'

    if ([string]::IsNullOrWhiteSpace($WorkDirectory)) {
        $here = Get-Location
        if ($here.Provider.Name -ne 'FileSystem') {
            Stop-BlackFrame 'Current location is not a filesystem path.'
        }
        $work = $here.ProviderPath
    } else {
        if (-not (Test-Path -LiteralPath $WorkDirectory)) {
            Stop-BlackFrame "No such directory: $WorkDirectory"
        }
        $item = Get-Item -LiteralPath $WorkDirectory
        if (-not $item.PSIsContainer) {
            Stop-BlackFrame "Not a directory: $WorkDirectory"
        }
        $work = $item.FullName
    }

    $lq = Join-Path $work 'lq_previews'
    if (-not (Test-Path -LiteralPath $lq)) {
        Stop-BlackFrame "No lq_previews in $work"
    }

    $script:Source = Find-SourceVideo $work
    $stem = [IO.Path]::GetFileNameWithoutExtension($script:Source)

    $h264Sw = @(
        '-c:v', 'libx264',
        '-preset', 'slow',
        '-tune', 'film',
        '-crf', '18',
        '-profile:v', 'high',
        '-pix_fmt', 'yuv420p'
    )
    $h265Sw = @(
        '-c:v', 'libx265',
        '-preset', 'medium',
        '-crf', '20',
        '-pix_fmt', 'yuv420p10le',
        '-profile:v', 'main10',
        '-tag:v', 'hvc1',
        '-x265-params', 'aq-mode=3:qg-size=32:psy-rd=2.0:psy-rdoq=1.0:rdoq-level=2:deblock=-1,-1:sao=0:strong-intra-smoothing=0:bframes=6:rc-lookahead=40:ref=4'
    )
    $h264P7 = @(
        '-c:v', 'h264_nvenc',
        '-preset', 'p7',
        '-tune', 'hq',
        '-rc', 'vbr',
        '-cq', '18',
        '-b:v', '0',
        '-profile:v', 'high',
        '-pix_fmt', 'yuv420p',
        '-spatial-aq', '1',
        '-temporal-aq', '1',
        '-rc-lookahead', '32',
        '-bf', '3'
    )
    $h264Hq = @(
        '-c:v', 'h264_nvenc',
        '-preset', 'hq',
        '-tune', 'hq',
        '-rc', 'vbr',
        '-cq', '18',
        '-b:v', '0',
        '-profile:v', 'high',
        '-pix_fmt', 'yuv420p',
        '-spatial-aq', '1',
        '-temporal-aq', '1',
        '-rc-lookahead', '32',
        '-bf', '3'
    )
    $h265P7 = @(
        '-c:v', 'hevc_nvenc',
        '-preset', 'p7',
        '-tune', 'hq',
        '-rc', 'vbr',
        '-cq', '20',
        '-b:v', '0',
        '-profile:v', 'main10',
        '-pix_fmt', 'p010le',
        '-tag:v', 'hvc1',
        '-spatial-aq', '1',
        '-temporal-aq', '1',
        '-rc-lookahead', '32',
        '-bf', '3'
    )
    $h265Hq = @(
        '-c:v', 'hevc_nvenc',
        '-preset', 'hq',
        '-tune', 'hq',
        '-rc', 'vbr',
        '-cq', '20',
        '-b:v', '0',
        '-profile:v', 'main10',
        '-pix_fmt', 'p010le',
        '-tag:v', 'hvc1',
        '-spatial-aq', '1',
        '-temporal-aq', '1',
        '-rc-lookahead', '32',
        '-bf', '3'
    )

    if ($Codec -eq 'h265') {
        $suffix = 'h265'
        $segName = 'hq_segments_h265'
        Select-Encoder -NvName 'hevc_nvenc' -SwName 'libx265' `
            -SwArgs $h265Sw -NvP7 $h265P7 -NvHq $h265Hq `
            -LabelSw 'x265 main10 medium CRF 20' `
            -LabelP7 'NVENC hevc_nvenc p7 tune hq vbr cq 20 main10' `
            -LabelHq 'NVENC hevc_nvenc hq tune hq vbr cq 20 main10'
    } else {
        $suffix = 'h264'
        $segName = 'hq_segments'
        Select-Encoder -NvName 'h264_nvenc' -SwName 'libx264' `
            -SwArgs $h264Sw -NvP7 $h264P7 -NvHq $h264Hq `
            -LabelSw 'x264 slow tune film CRF 18' `
            -LabelP7 'NVENC h264_nvenc p7 tune hq vbr cq 18' `
            -LabelHq 'NVENC h264_nvenc hq tune hq vbr cq 18'
    }

    $output = Join-Path $work ($stem + '.' + $suffix + '.mp4')
    $rows = Get-ClipRows $lq
    $sorted = @($rows | Sort-Object Id)
    if ($sorted.Count -eq 0) {
        if ($Mode -eq 'continuous') {
            Stop-BlackFrame "No valid LQ clips found in $lq"
        }
        Stop-BlackFrame "No LQ clips left in $lq"
    }

    Write-Host 'Source:  ' -ForegroundColor White -NoNewline
    Write-Host $script:Source
    Write-Host 'Output:  ' -ForegroundColor White -NoNewline
    Write-Host $output

    if ($Mode -eq 'continuous') {
        $minStart = $sorted[0].Start
        $maxStop = $sorted[0].Stop
        foreach ($row in $sorted) {
            if ($row.Start -lt $minStart) { $minStart = $row.Start }
            if ($row.Stop -gt $maxStop) { $maxStop = $row.Stop }
        }
        $len = $maxStop - $minStart
        Write-Host 'Range:   ' -ForegroundColor White -NoNewline
        Write-Host ("{0} -> {1}  ({2}s), {3}" -f (Format-Seconds $minStart), (Format-Seconds $maxStop), (Format-Seconds $len), $script:Label)
        Wait-ForCpu
        Write-Good ("Encoding continuous range  {0}-{1} ({2}s)" -f (Format-Seconds $minStart), (Format-Seconds $maxStop), (Format-Seconds $len))
        $inputArgs = @(
            '-ss', (Format-Seconds $minStart),
            '-i', $script:Source,
            '-t', (Format-Seconds $len)
        )
        Invoke-RunEncode -OutFile $output -InputArgs $inputArgs -FailLabel ([IO.Path]::GetFileName($output))
        Write-Host 'Done: ' -ForegroundColor Green -NoNewline
        Write-Host $output
        return
    }

    Write-Host 'Keeping ' -ForegroundColor White -NoNewline
    Write-Host $sorted.Count -ForegroundColor Cyan -NoNewline
    Write-Host " clip(s), $($script:Label), one encode at a time" -ForegroundColor White

    $total = [decimal]0
    foreach ($row in $sorted) {
        $len = $row.Stop - $row.Start
        $total += $len
        Write-Host ("  Clip {0:D3}  {1} -> {2}  ({3}s)" -f $row.Id, (Format-Seconds $row.Start), (Format-Seconds $row.Stop), (Format-Seconds $len))
    }
    Write-Host ("  Total kept: {0}s" -f (Format-Seconds $total))
    Write-Host ''

    Wait-ForCpu

    $segDir = Join-Path $work $segName
    if (Test-Path -LiteralPath $segDir) {
        Remove-Item -LiteralPath $segDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $segDir | Out-Null
    $list = Join-Path $segDir 'concat.txt'
    $lines = New-Object System.Collections.Generic.List[string]

    foreach ($row in $sorted) {
        $idpad = '{0:D3}' -f $row.Id
        $len = $row.Stop - $row.Start
        $pre = [decimal]10
        if ($row.Start -ge $pre) {
            $prestart = $row.Start - $pre
            $acc = $pre
        } else {
            $prestart = [decimal]0
            $acc = $row.Start
        }
        $seg = Join-Path $segDir ("HQ_Clip{0}.mp4" -f $idpad)
        Write-Good ("HQ Clip {0}  {1}-{2} ({3}s)" -f $idpad, (Format-Seconds $row.Start), (Format-Seconds $row.Stop), (Format-Seconds $len))
        $inputArgs = @(
            '-ss', (Format-Seconds $prestart),
            '-i', $script:Source,
            '-ss', (Format-Seconds $acc),
            '-t', (Format-Seconds $len)
        )
        Invoke-RunEncode -OutFile $seg -InputArgs $inputArgs -FailLabel $idpad
        $lines.Add((ConvertTo-ConcatLine $seg))
    }

    Set-Content -LiteralPath $list -Value $lines.ToArray() -Encoding ascii
    Write-Host 'Joining segments -> ' -ForegroundColor White -NoNewline
    Write-Host $output -ForegroundColor Cyan
    $concat = @(
        '-nostdin', '-hide_banner', '-stats', '-loglevel', 'error',
        '-f', 'concat', '-safe', '0', '-i', $list,
        '-c', 'copy', '-movflags', '+faststart',
        '-y', $output
    )
    & ffmpeg @concat
    if ($LASTEXITCODE -ne 0) {
        Stop-BlackFrame "concat failed: $output"
    }
    Remove-Item -LiteralPath $segDir -Recurse -Force
    Write-Host 'Done: ' -ForegroundColor Green -NoNewline
    Write-Host $output
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-BlackFrameCompile -Codec h264 -WorkDirectory $WorkDirectory -Mode clips
}
