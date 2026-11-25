#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:26 AM MST
PowerShell clone of gitBinUpdate.
The bash script is unchanged.

Refresh repo files in an existing checkout from the public HTTPS URL.
Overwrites files that are in the repo, except anything under archive/.
Before replacing a file whose content or mode differs, archives the local copy
as <name>.YYYYMMDD_HHMMSS (Mountain Time).
After writing, restores the executable bit on any file that starts with a shebang
when this system has chmod. On Windows, the bit is restored in the git index.
Leaves every other file in the directory alone. Does not git clean, and does
not reset --hard.
Does not read or write SSH keys or SSH config.
Does not create a checkout.
If the origin is the SSH form of this repository, it is rewritten to HTTPS.

  .\gitBinUpdate.ps1
  .\gitBinUpdate.ps1 "$env:USERPROFILE\bin"
#>

param(
    [Parameter(Position = 0)]
    [string]$Directory,
    [Alias('h')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$Revision = '20261031_0120'
$DefaultBranch = 'main'
$DefaultRemote = 'https://github.com/eckirchn/Bash.git'

function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor White }
function Write-Good([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Bad([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Accent([string]$Message) { Write-Host $Message -ForegroundColor Cyan }
function Write-Note([string]$Message) { Write-Host $Message -ForegroundColor Magenta }

function Stop-Bin([string]$Message) {
    Write-Bad $Message
    exit 1
}

function Show-Revision {
    Write-Host 'Script Revision:  ' -ForegroundColor White -NoNewline
    Write-Host $Revision -ForegroundColor Yellow
    Write-Note '  Updates over HTTPS. Skips archive/. Archives differing files. Restores +x.'
    Write-Host ''
}

function Show-Usage {
    @'
Usage: .\gitBinUpdate.ps1 [directory]

  directory    Where the scripts live. Default: $env:USERPROFILE\bin

The directory must already be a checkout of this repository.
This script does not clone and does not create a checkout.
Files already there that are not in the repo are not removed.
Files that are in the repo are replaced from the public HTTPS URL.
Anything under archive/ is skipped and is never downloaded or updated.
A local file whose content or mode differs is first renamed to
  <name>.YYYYMMDD_HHMMSS   (Mountain Time)
After the update, any file that starts with a shebang is made executable
when chmod exists. On Windows the executable bit is restored in the git index.
Does not change SSH keys, SSH config, or git settings outside that directory.
If the origin is the SSH form of this repository, it is rewritten to HTTPS.
A fetch does not need a login or an SSH key.

  GIT_BIN_BRANCH   Default: main

First install:

  git clone https://github.com/eckirchn/Bash.git "$env:USERPROFILE\bin"

Then:

  .\gitBinUpdate.ps1
  .\gitBinUpdate.ps1 "$env:USERPROFILE\bin"
'@
}

function Get-RepoSlug([string]$Url) {
    $url = $Url -replace '\.git$', ''
    $url = $url.TrimEnd('/')
    if ($url -match '^[A-Za-z0-9._+-]+@[^:]+:(.+)$') { return $Matches[1] }
    if ($url -match '^[A-Za-z][A-Za-z0-9+.-]*://([^/]*)/(.+)$') { return $Matches[2] }
    return $url
}

function Test-SameRepo([string]$Left, [string]$Right) {
    return ((Get-RepoSlug $Left).ToLowerInvariant() -eq (Get-RepoSlug $Right).ToLowerInvariant())
}

function Resolve-BinDir([string]$Requested) {
    if (-not (Test-Path -LiteralPath $Requested)) {
        Stop-Bin "$Requested does not exist. First install: git clone $DefaultRemote `"`$env:USERPROFILE\bin`""
    }
    $item = Get-Item -LiteralPath $Requested
    if (-not $item.PSIsContainer) {
        Stop-Bin "$Requested is not a directory."
    }
    $resolved = $item.FullName
    $homeDir = [Environment]::GetFolderPath('UserProfile')
    $root = [IO.Path]::GetPathRoot($resolved)
    if ($resolved.TrimEnd('\', '/') -eq $root.TrimEnd('\', '/') -or $resolved.TrimEnd('\', '/') -eq $homeDir.TrimEnd('\', '/')) {
        Stop-Bin "Refusing to use $resolved. Use a directory such as `$env:USERPROFILE\bin."
    }
    return $resolved
}

function Assert-Checkout([string]$Bin) {
    $gitPath = Join-Path $Bin '.git'
    if (Test-Path -LiteralPath $gitPath -PathType Leaf) {
        Stop-Bin "$gitPath is a file, not a checkout. Not touching it."
    }
    if (-not (Test-Path -LiteralPath $gitPath -PathType Container)) {
        Stop-Bin "$Bin is not a git checkout. First install: git clone $DefaultRemote `"`$env:USERPROFILE\bin`""
    }
    & git -C $Bin rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        Stop-Bin "$Bin has a .git directory this git does not understand. Not touching it."
    }
    $current = (& git -C $Bin remote get-url origin 2>$null | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($current)) {
        Stop-Bin "$Bin has no origin. First install: git clone $DefaultRemote `"`$env:USERPROFILE\bin`""
    }
    if (-not (Test-SameRepo $current $DefaultRemote)) {
        Stop-Bin "$Bin already tracks $current. Refusing to switch it to $DefaultRemote."
    }
}

function Set-HttpsOrigin([string]$Bin) {
    $current = (& git -C $Bin remote get-url origin | Out-String).Trim()
    if ($current -eq $DefaultRemote) { return }
    Write-Host 'Rewriting origin to ' -ForegroundColor White -NoNewline
    Write-Host $DefaultRemote -ForegroundColor Cyan
    & git -C $Bin remote set-url origin $DefaultRemote
    if ($LASTEXITCODE -ne 0) { Stop-Bin 'Could not rewrite origin.' }
}

function Test-SkipPath([string]$Path) {
    $p = $Path.Replace('\', '/')
    return ($p -eq 'archive' -or $p.StartsWith('archive/'))
}

function Get-OriginMode([string]$Bin, [string]$Branch, [string]$Path) {
    $line = & git -C $Bin ls-tree "origin/$Branch" -- $Path
    $text = @($line) -join "`n"
    if ($text -match '^(\d+)\s') { return $Matches[1] }
    return ''
}

function Test-LocalExecutable([string]$Bin, [string]$Path) {
    $full = Join-Path $Bin ($Path.Replace('/', [IO.Path]::DirectorySeparatorChar))
    if (Get-Command chmod -ErrorAction SilentlyContinue) {
        & bash -c 'test -x "$1"' bash $full
        if ($LASTEXITCODE -eq 0) { return $true }
        if ($LASTEXITCODE -eq 1) { return $false }
    }
    $line = (& git -C $Bin ls-files -s -- $Path | Out-String).Trim()
    return $line.StartsWith('100755')
}

function Test-LocalDiffers([string]$Bin, [string]$Branch, [string]$Path) {
    & git -C $Bin diff --quiet "origin/$Branch" -- $Path 2>$null
    if ($LASTEXITCODE -ne 0) { return $true }
    $want = Get-OriginMode $Bin $Branch $Path
    $full = Join-Path $Bin ($Path.Replace('/', [IO.Path]::DirectorySeparatorChar))
    if ((Test-Path -LiteralPath $full -PathType Leaf) -and $want) {
        $localMode = if (Test-LocalExecutable $Bin $Path) { '100755' } else { '100644' }
        if ($want -ne $localMode) { return $true }
    }
    return $false
}

function Get-MountainStamp {
    $utc = [DateTime]::UtcNow
    $tz = [TimeZoneInfo]::FindSystemTimeZoneById('America/Denver')
    return [TimeZoneInfo]::ConvertTimeFromUtc($utc, $tz).ToString('yyyyMMdd_HHmmss')
}

function Move-IfDifferent([string]$Bin, [string]$Branch, [string]$Path) {
    $full = Join-Path $Bin ($Path.Replace('/', [IO.Path]::DirectorySeparatorChar))
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { return }
    if (-not (Test-LocalDiffers $Bin $Branch $Path)) { return }
    $stamp = Get-MountainStamp
    $archive = "$full.$stamp"
    $n = 1
    while (Test-Path -LiteralPath $archive) {
        $archive = "$full.${stamp}_$n"
        $n++
    }
    Write-Host 'Archiving differing local ' -ForegroundColor Yellow -NoNewline
    Write-Host $Path -ForegroundColor Cyan -NoNewline
    Write-Host ' as ' -ForegroundColor Yellow -NoNewline
    Write-Host ([IO.Path]::GetFileName($archive)) -ForegroundColor Cyan
    Move-Item -LiteralPath $full -Destination $archive
}

function Restore-ShebangExec([string]$Bin) {
    $paths = @(& git -C $Bin ls-tree -r --name-only HEAD)
    foreach ($path in $paths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        if (Test-SkipPath $path) { continue }
        $full = Join-Path $Bin ($path.Replace('/', [IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        $first = Get-Content -LiteralPath $full -TotalCount 1 -ErrorAction SilentlyContinue
        if ("$first" -notmatch '^#!') { continue }
        if (Test-LocalExecutable $Bin $path) { continue }
        if (Get-Command chmod -ErrorAction SilentlyContinue) {
            & chmod +x $full
            if ($LASTEXITCODE -eq 0) {
                Write-Host 'Restored +x on ' -ForegroundColor Green -NoNewline
                Write-Host $path -ForegroundColor Cyan
                continue
            }
        }
        & git -C $Bin update-index --chmod=+x -- $path
        if ($LASTEXITCODE -eq 0) {
            Write-Host 'Restored +x in the git index on ' -ForegroundColor Green -NoNewline
            Write-Host $path -ForegroundColor Cyan
        }
    }
}

function Write-RepoFiles([string]$Bin, [string]$Branch) {
    $paths = @(& git -C $Bin ls-tree -r --name-only "origin/$Branch")
    foreach ($path in $paths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        if (Test-SkipPath $path) { continue }
        Move-IfDifferent $Bin $Branch $path
        & git -C $Bin checkout -f "origin/$Branch" -- $path
        if ($LASTEXITCODE -ne 0) { Stop-Bin "Could not write $path" }
    }
    & git -C $Bin symbolic-ref HEAD "refs/heads/$Branch"
    if ($LASTEXITCODE -ne 0) { Stop-Bin "Could not point HEAD at $Branch" }
    & git -C $Bin reset --mixed "origin/$Branch" *> $null
    if ($LASTEXITCODE -ne 0) { Stop-Bin 'git reset --mixed failed.' }
    Restore-ShebangExec $Bin
}

function Invoke-GitFetch([string]$Bin, [string]$Branch) {
    $prefix = 'https://github.com'
    & git -C $Bin -c "url.${prefix}/.insteadOf=${prefix}/" fetch origin $Branch
    return ($LASTEXITCODE -eq 0)
}

function Show-LocalFiles([string]$Bin) {
    $status = @(& git -C $Bin status --porcelain=v1 --untracked-files=all)
    $shown = $false
    foreach ($line in $status) {
        if ($line -notmatch '^\?\? ') { continue }
        if (-not $shown) {
            Write-Info 'Left in place, not in the repo:'
            $shown = $true
        }
        Write-Accent ("  " + $line.Substring(3))
    }
    if (-not $shown) {
        Write-Info 'No extra local files.'
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

Show-Revision

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Stop-Bin 'git is not installed.'
}
if ([string]::IsNullOrWhiteSpace($env:USERPROFILE) -and [string]::IsNullOrWhiteSpace($env:HOME)) {
    Stop-Bin 'HOME is not set.'
}
$branch = if ($env:GIT_BIN_BRANCH) { $env:GIT_BIN_BRANCH } else { $DefaultBranch }
if ($branch -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$' -or $branch.Contains('..')) {
    Stop-Bin "Branch name is not usable: $branch"
}
if ([string]::IsNullOrWhiteSpace($Directory)) {
    $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $Directory = Join-Path $homeDir 'bin'
}
$bin = Resolve-BinDir $Directory
Assert-Checkout $bin
Set-HttpsOrigin $bin
& git -C $bin config core.autocrlf false
if ($LASTEXITCODE -ne 0) { Stop-Bin 'Could not set core.autocrlf false.' }

Write-Host 'Fetching ' -ForegroundColor White -NoNewline
Write-Host $DefaultRemote -ForegroundColor Cyan -NoNewline
Write-Host " ($branch)" -ForegroundColor White
if (-not (Invoke-GitFetch $bin $branch)) {
    Write-Bad 'Could not fetch.'
    exit 1
}
& git -C $bin rev-parse --verify --quiet "origin/$branch" *> $null
if ($LASTEXITCODE -ne 0) { Stop-Bin "Remote has no branch $branch." }

$paths = @(& git -C $bin ls-tree -r --name-only "origin/$branch")
$count = 0
foreach ($path in $paths) {
    if ([string]::IsNullOrWhiteSpace($path)) { continue }
    if (Test-SkipPath $path) { continue }
    $count++
}
$noun = if ($count -eq 1) { 'file' } else { 'files' }
Write-Host 'Writing ' -ForegroundColor White -NoNewline
Write-Host $count -ForegroundColor Cyan -NoNewline
Write-Host " repo $noun into " -ForegroundColor White -NoNewline
Write-Host $bin -ForegroundColor Cyan
Write-Info 'Skipping archive/. Differing local files are archived first. Files that are not in the repo are not deleted.'
Write-RepoFiles $bin $branch

Write-Good 'Updated the repo files.'
Write-Host ''
Show-LocalFiles $bin
Write-Host ''
Write-Info 'Next time, from any directory:'
Write-Warn '  .\gitBinUpdate.ps1'
