#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:26 AM MST
PowerShell clone of blackframeextract.
The bash script is unchanged.

Find black-frame cut points and write preview clips for review.
The source file is moved into a folder named after it only after the
whole run finishes successfully:
  MyClip.mp4  ->  MyClip/MyClip.mp4
If anything fails, the source stays where it was.

Detection skips B-frames and measures black on a 160px-wide image.
Previews are 288p, ultrafast, CRF 26. Same flags as the bash script.
The times are calculated here, so bc is not required.

  .\blackframeextract.ps1 .\MyClip.mp4
#>

param(
    [Parameter(Position = 0)]
    [string]$VideoFile
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor White }
function Write-Good([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Bad([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Accent([string]$Message) { Write-Host $Message -ForegroundColor Cyan }
function Write-Note([string]$Message) { Write-Host $Message -ForegroundColor Magenta }

function Show-Revision {
    Write-Host 'Script Revision:  ' -ForegroundColor White -NoNewline
    Write-Host '20261031_0138' -ForegroundColor Yellow
    Write-Note '  blackframeextract, move source only on success, faster blackdetect, 288p previews'
    Write-Host ''
}

function Test-Dependencies {
    $missing = $false
    Write-Info 'Dependency check'
    foreach ($cmd in @('ffmpeg', 'ffprobe')) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            Write-Host "  ${cmd}: " -NoNewline
            Write-Host 'OK' -ForegroundColor Green
        } else {
            Write-Host "  missing: $cmd" -ForegroundColor Red
            Write-Warn '  Put ffmpeg.exe and ffprobe.exe on PATH. On Debian: sudo apt install ffmpeg'
            $missing = $true
        }
    }
    if ($missing) {
        Write-Bad 'Dependencies missing. Exiting.'
        exit 1
    }
    Write-Host ''
}

function Format-Fixed([decimal]$Value, [string]$Picture) {
    return $Value.ToString($Picture, [Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-DecimalText([string]$Text) {
    $Text = ($Text -replace "`r", '').Trim()
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return [decimal]0
    }
    return [decimal]::Parse($Text, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-FpsValue([string]$Rate) {
    $Rate = ($Rate -replace "`r", '').Trim()
    if ($Rate -match '^([0-9.]+)/([0-9.]+)$') {
        $den = ConvertTo-DecimalText $Matches[2]
        if ($den -eq 0) { return [decimal]0 }
        return (ConvertTo-DecimalText $Matches[1]) / $den
    }
    return ConvertTo-DecimalText $Rate
}

function Get-ProbeLine([string[]]$FfArgs) {
    $out = & ffprobe @FfArgs 2>$null
    if (-not $out) { return '' }
    $line = @($out)[0]
    if ($null -eq $line) { return '' }
    return ($line.ToString() -replace "`r", '').Trim()
}

function Get-VideoFps([string]$File) {
    $line = Get-ProbeLine @(
        '-v', 'error', '-select_streams', 'v:0',
        '-show_entries', 'stream=r_frame_rate', '-of', 'csv=p=0', $File
    )
    return Get-FpsValue $line
}

function Get-VideoDuration([string]$File) {
    $line = Get-ProbeLine @(
        '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', $File
    )
    return ConvertTo-DecimalText $line
}

function Write-Utf8Lines([string]$Path, [string[]]$Lines) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllLines($Path, $Lines, $utf8)
}

function Invoke-BlackDetect([string]$Infile, [string]$Outfile) {
    $d = '0.15'
    $picTh = '0.98'
    $pixTh = '0.12'
    Write-Host 'Running blackdetect on ' -ForegroundColor White -NoNewline
    Write-Host $Infile -ForegroundColor Cyan
    $vf = "scale=160:-2:flags=fast_bilinear,blackdetect=d=${d}:pic_th=${picTh}:pix_th=${pixTh}"
    $raw = & ffmpeg -nostdin -hide_banner -loglevel info -threads 0 -skip_frame bidir -i $Infile -vf $vf -an -sn -f null - 2>&1
    $rows = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($raw)) {
        $text = "$item"
        if ($text -match 'black_start:([0-9.]+).*black_end:([0-9.]+).*black_duration:([0-9.]+)') {
            $rows.Add("$($Matches[1]) $($Matches[2]) $($Matches[3])")
        }
    }
    if ($rows.Count -eq 0) {
        Write-Warn 'No black segments detected. Creating empty log.'
        Write-Utf8Lines $Outfile @()
    } else {
        Write-Utf8Lines $Outfile $rows.ToArray()
    }
    Write-Host 'Black segments written to ' -ForegroundColor Green -NoNewline
    Write-Host $Outfile
    Write-Host ''
}

function Write-ClipLog([string]$Infile, [string]$BlackLog, [string]$ClipLog) {
    $fps = Get-VideoFps $Infile
    $duration = Get-VideoDuration $Infile
    $lines = New-Object System.Collections.Generic.List[string]
    $clip = 0
    $prevEnd = [decimal]0
    $blackLines = @()
    if (Test-Path -LiteralPath $BlackLog) {
        $blackLines = @(Get-Content -LiteralPath $BlackLog)
    }
    foreach ($row in $blackLines) {
        if ([string]::IsNullOrWhiteSpace($row)) { continue }
        $parts = $row.Trim() -split '\s+'
        if ($parts.Count -lt 2) { continue }
        $start = ConvertTo-DecimalText $parts[0]
        $end = ConvertTo-DecimalText $parts[1]
        $mid = ($start + $end) / 2
        $clip++
        $cfill = '{0:D3}' -f $clip
        $fstart = [decimal]::Round($prevEnd * $fps, 0, [MidpointRounding]::AwayFromZero)
        $fstop = [decimal]::Round($mid * $fps, 0, [MidpointRounding]::AwayFromZero)
        $tstart = Format-Fixed $prevEnd '000000.000000'
        $tstop = Format-Fixed $mid '000000.000000'
        $lines.Add("Clip:$cfill fStart:$fstart fStop:$fstop tStart:$tstart tStop:$tstop")
        Write-Host "Clip " -ForegroundColor White -NoNewline
        Write-Host $cfill -ForegroundColor Cyan -NoNewline
        Write-Host '  ' -NoNewline
        Write-Host $tstart -ForegroundColor Green -NoNewline
        Write-Host ' -> ' -ForegroundColor White -NoNewline
        Write-Host $tstop -ForegroundColor Red
        $prevEnd = $mid
    }
    $clip++
    $cfill = '{0:D3}' -f $clip
    $tstart = Format-Fixed $prevEnd '000000.000000'
    $tstop = Format-Fixed $duration '000000.000000'
    $lines.Add("Clip:$cfill fStart:0 fStop:0 tStart:$tstart tStop:$tstop")
    Write-Host "Clip " -ForegroundColor White -NoNewline
    Write-Host $cfill -ForegroundColor Cyan -NoNewline
    Write-Host '  ' -NoNewline
    Write-Host $tstart -ForegroundColor Green -NoNewline
    Write-Host ' -> ' -ForegroundColor White -NoNewline
    Write-Host $tstop -ForegroundColor Red -NoNewline
    Write-Host ' (to end)'
    Write-Host ''
    Write-Utf8Lines $ClipLog $lines.ToArray()
}

function Invoke-PreviewClips([string]$Infile, [string]$ClipLog, [string]$OutDir) {
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    Write-Host 'Generating preview clips into ' -ForegroundColor White -NoNewline
    Write-Host $OutDir -ForegroundColor Cyan
    $rows = @()
    if (Test-Path -LiteralPath $ClipLog) {
        $rows = @(Get-Content -LiteralPath $ClipLog)
    }
    foreach ($line in $rows) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch 'Clip:(\S+)\s') { continue }
        $clip = $Matches[1]
        if ($line -notmatch 'tStart:([0-9.]+)') { continue }
        $tstartText = $Matches[1]
        if ($line -notmatch 'tStop:([0-9.]+)') { continue }
        $tstopText = $Matches[1]
        $tstart = ConvertTo-DecimalText $tstartText
        $tstop = ConvertTo-DecimalText $tstopText
        $length = $tstop - $tstart
        $outfile = Join-Path $OutDir ("LQ_Clip{0}_{1}-{2}.mp4" -f $clip, $tstartText, $tstopText)
        Write-Host "Preview $clip  " -ForegroundColor Green -NoNewline
        Write-Host ("{0}-{1} ({2}s)" -f $tstartText, $tstopText, (Format-Fixed $length '0.################'))
        $pre = [decimal]10
        if ($tstart -ge $pre) {
            $prestart = $tstart - $pre
            $acc = $pre
        } else {
            $prestart = [decimal]0
            $acc = $tstart
        }
        $ff = @(
            '-nostdin', '-hide_banner', '-stats', '-loglevel', 'error',
            '-ss', (Format-Fixed $prestart '0.################'),
            '-i', $Infile,
            '-ss', (Format-Fixed $acc '0.################'),
            '-t', (Format-Fixed $length '0.################'),
            '-threads', '0', '-c:v', 'libx264', '-preset', 'ultrafast',
            '-vf', 'scale=-2:288', '-crf', '26', '-movflags', '+faststart',
            '-c:a', 'copy', '-y', $outfile
        )
        & ffmpeg @ff
        if ($LASTEXITCODE -ne 0) {
            Write-Bad "Failed: $outfile"
        }
    }
    Write-Host ''
}

function Write-HqLauncher([string]$HqScript) {
    $body = @'
# Delete the previews you do not want, then run this.
# It encodes the clips still in lq_previews into MyClip.h264.mp4.
Set-Location -LiteralPath $PSScriptRoot
$compile = Get-Command h264BlackFrameCompile.ps1 -ErrorAction SilentlyContinue
if (-not $compile) {
    Write-Host 'h264BlackFrameCompile.ps1 is not on PATH.' -ForegroundColor Red
    exit 1
}
& $compile.Source $PSScriptRoot
'@
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($HqScript, $body.Replace("`n", "`r`n"), $utf8)
    Write-Host 'HQ launcher written: ' -ForegroundColor Green -NoNewline
    Write-Host $HqScript -ForegroundColor Cyan
    Write-Warn "After deleting unwanted previews: powershell -File `"$HqScript`""
    Write-Host ''
}

Show-Revision
Test-Dependencies

if ([string]::IsNullOrWhiteSpace($VideoFile)) {
    Write-Bad 'Usage: .\blackframeextract.ps1 <video-file>'
    exit 1
}
if (-not (Test-Path -LiteralPath $VideoFile -PathType Leaf)) {
    Write-Bad "File not found: $VideoFile"
    exit 1
}

$infile = (Get-Item -LiteralPath $VideoFile).FullName
$base = [IO.Path]::GetFileName($infile)
$bname = [IO.Path]::GetFileNameWithoutExtension($infile)
$parent = [IO.Path]::GetDirectoryName($infile)
$already = $false
$dest = ''

if ([IO.Path]::GetFileName($parent) -eq $bname) {
    $work = $parent
    $already = $true
} else {
    $work = Join-Path $parent $bname
    if ((Test-Path -LiteralPath $work) -and -not (Get-Item -LiteralPath $work).PSIsContainer) {
        Write-Bad "Cannot create folder (a file is in the way): $work"
        exit 1
    }
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $dest = Join-Path $work $base
    if (Test-Path -LiteralPath $dest) {
        Write-Bad "Refusing to move; already exists: $dest"
        exit 1
    }
}

$blackLog = Join-Path $work ($bname + '_black.log')
$clipLog = Join-Path $work ($bname + '_clips.log')
$lqDir = Join-Path $work 'lq_previews'
$hqScript = Join-Path $work ($bname + '_hq.ps1')

Invoke-BlackDetect $infile $blackLog
Write-ClipLog $infile $blackLog $clipLog
Invoke-PreviewClips $infile $clipLog $lqDir
Write-HqLauncher $hqScript

if (-not $already) {
    Write-Info 'All steps finished. Moving source into work folder...'
    Move-Item -LiteralPath $infile -Destination $dest
    Write-Host "Source moved: $dest" -ForegroundColor Green
} else {
    Write-Info 'Source already in work folder. Left in place.'
}

Write-Good 'Done.'
Write-Host 'Folder:      ' -NoNewline; Write-Host $work -ForegroundColor Cyan
Write-Host 'Source:      ' -NoNewline; Write-Host (Join-Path $work $base) -ForegroundColor Cyan
Write-Host 'Previews:    ' -NoNewline; Write-Host $lqDir -ForegroundColor Cyan
Write-Host 'HQ launcher: ' -NoNewline; Write-Host $hqScript -ForegroundColor Cyan
Write-Host 'Black log:   ' -NoNewline; Write-Host $blackLog -ForegroundColor Cyan
Write-Host 'Clip log:    ' -NoNewline; Write-Host $clipLog -ForegroundColor Cyan
Write-Host ''
Write-Info 'Delete the previews you do not want, then run h264BlackFrameCompile.ps1 or h265BlackFrameCompile.ps1 here.'
