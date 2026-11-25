#Requires -Version 5.1
<#
Updated: 25 November 2026, 12:26 AM MST
PowerShell clone of SwitchBot_Update.
The bash script is unchanged.

Update an existing SwitchBot-App install under the home directory.
This still uses apt, dpkg, git, npm, curl, and python3. It is the same
Linux update, written as PowerShell. It does not become a Windows installer.
Do not run the whole script elevated. sudo is used only for apt.

  .\SwitchBot_Update.ps1
#>

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$HomeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
$InstallDir = if ($env:SWITCHBOT_HOME) { $env:SWITCHBOT_HOME } else { Join-Path $HomeDir 'SwitchBot-App' }
$Raw = if ($env:SWITCHBOT_RAW) { $env:SWITCHBOT_RAW } else { 'https://raw.githubusercontent.com/eckirchn/Bash/main/switchbot' }
$ScriptUrl = 'https://raw.githubusercontent.com/eckirchn/Bash/main/ps/SwitchBot_Update.ps1'

function Stop-Update([string]$Message) {
    Write-Host $Message -ForegroundColor Red
    exit 1
}

function Invoke-Checked([scriptblock]$Command) {
    & $Command
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if ($env:SWITCHBOT_UPDATE_INNER -ne '1') {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('SwitchBot_Update-' + [guid]::NewGuid().ToString('n') + '.ps1')
    & curl -fsSL $ScriptUrl -o $tmp
    if ($LASTEXITCODE -ne 0) { Stop-Update "Could not download $ScriptUrl" }
    $bin = Join-Path $HomeDir 'bin'
    New-Item -ItemType Directory -Force -Path $bin | Out-Null
    Copy-Item -LiteralPath $tmp -Destination (Join-Path $bin 'SwitchBot_Update.ps1') -Force
    $env:SWITCHBOT_UPDATE_INNER = '1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $tmp
    exit $LASTEXITCODE
}

Write-Host '=== SwitchBot-App update ==='
Write-Host "Install location: $InstallDir"
Write-Host "Fixes from:       $Raw"
Write-Host ''

foreach ($cmd in @('git', 'npm', 'curl')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Stop-Update "Error: $cmd is not installed."
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $InstallDir '.git') -PathType Container)) {
    Write-Host "Error: $InstallDir is not an existing git checkout."
    Stop-Update 'Run SwitchBot_Install first.'
}

function Install-SystemDeps {
    $required = @(
        'build-essential',
        'python3',
        'pkg-config',
        'libudev-dev',
        'libusb-1.0-0-dev',
        'libnss3',
        'libnspr4',
        'libatk1.0-0|libatk1.0-0t64',
        'libatk-bridge2.0-0|libatk-bridge2.0-0t64',
        'libcups2|libcups2t64',
        'libdrm2',
        'libgbm1',
        'libgtk-3-0|libgtk-3-0t64',
        'libasound2|libasound2t64',
        'libxcomposite1',
        'libxdamage1',
        'libxfixes3',
        'libxrandr2',
        'libxkbcommon0',
        'libxshmfence1',
        'libxss1',
        'libpango-1.0-0',
        'libcairo2',
        'libx11-xcb1'
    )
    if (-not (Get-Command apt-get -ErrorAction SilentlyContinue) -or -not (Get-Command dpkg -ErrorAction SilentlyContinue)) {
        Write-Host 'Error: this script installs system packages with apt.'
        Write-Host 'Install these packages yourself, then re-run:'
        foreach ($spec in $required) { Write-Host "  $spec" }
        exit 1
    }
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($spec in $required) {
        $primary = $spec.Split('|')[0]
        $alt = ''
        if ($spec.Contains('|')) { $alt = $spec.Split('|')[1] }
        & dpkg -s $primary *> $null
        if ($LASTEXITCODE -eq 0) { continue }
        if ($alt) {
            & dpkg -s $alt *> $null
            if ($LASTEXITCODE -eq 0) { continue }
        }
        $useAlt = $false
        if ($alt) {
            & apt-cache show $alt *> $null
            $altOk = ($LASTEXITCODE -eq 0)
            & apt-cache show $primary *> $null
            $primaryOk = ($LASTEXITCODE -eq 0)
            if ($altOk -and -not $primaryOk) { $useAlt = $true }
        }
        if ($useAlt) { $missing.Add($alt) } else { $missing.Add($primary) }
    }
    if ($missing.Count -eq 0) {
        Write-Host '-> System packages already installed.'
        return
    }
    Write-Host ('-> Missing packages: ' + ($missing -join ' '))
    & sudo apt-get update
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & sudo apt-get install -y @($missing.ToArray())
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Set-ClientEnv {
    $envFile = Join-Path $InstallDir 'client/.env'
    if (Test-Path -LiteralPath $envFile) {
        $text = Get-Content -LiteralPath $envFile -Raw
        if ($text -match '(?m)^REACT_APP_SERVER_URL=.+') {
            Write-Host "-> Keeping $envFile"
            return
        }
    }
    $url = 'http://127.0.0.1:8089'
    $jsDir = Join-Path $InstallDir 'client/build/static/js'
    if (Test-Path -LiteralPath $jsDir) {
        $found = Select-String -Path (Join-Path $jsDir '*.js') -Pattern 'https?://[^"\s]+:8089' -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($found) { $url = $found.Matches[0].Value }
    }
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [IO.File]::WriteAllText($envFile, "REACT_APP_SERVER_URL=$url`n", $utf8)
    Write-Host "-> Wrote $envFile ($url)"
}

function Get-Fix([string]$Url, [string]$Dest) {
    $parent = Split-Path -Parent $Dest
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    & curl -fsSL $Url -o $Dest
    if ($LASTEXITCODE -ne 0) { Stop-Update "Could not download $Url" }
    Write-Host "-> $Dest"
}

Install-SystemDeps

Set-Location -LiteralPath $InstallDir
$branch = (& git rev-parse --abbrev-ref HEAD | Out-String).Trim()
if ($branch -eq 'HEAD') {
    Stop-Update 'Error: checkout is detached. Check out a branch, then re-run.'
}

$tracked = @(
    'desktop/main.js',
    'desktop/server/routes/switchbot.js',
    'server/routes/switchbot.js',
    'client/src/pages/Login.js',
    'desktop/server/services/localVariablesService.js',
    'server/services/localVariablesService.js'
)
foreach ($path in $tracked) {
    & git cat-file -e "HEAD:${path}" 2>$null
    if ($LASTEXITCODE -eq 0) {
        & git checkout -- $path
        if ($LASTEXITCODE -ne 0) { Stop-Update "Could not restore $path" }
    }
}

$oldRev = (& git rev-parse HEAD | Out-String).Trim()
Write-Host "-> Fetching origin/${branch}..."
& git fetch origin $branch
if ($LASTEXITCODE -ne 0) { Stop-Update 'git fetch failed.' }
& git merge --ff-only "origin/$branch"
if ($LASTEXITCODE -eq 0) {
    $newRev = (& git rev-parse HEAD | Out-String).Trim()
    if ($oldRev -eq $newRev) {
        Write-Host "-> Already at $($newRev.Substring(0, [Math]::Min(7, $newRev.Length)))."
    } else {
        Write-Host "-> Updated $($oldRev.Substring(0,7)) -> $($newRev.Substring(0,7))"
        & git log --oneline "$oldRev..$newRev"
    }
} else {
    Write-Host "-> Could not fast-forward $branch. Git history was left as it is."
    Write-Host '-> SwitchBot fixes will still be applied.'
}

Write-Host '-> Applying SwitchBot fixes...'
Get-Fix "$Raw/desktop/main.js" (Join-Path $InstallDir 'desktop/main.js')
Get-Fix "$Raw/login/switchbot.js" (Join-Path $InstallDir 'desktop/server/routes/switchbot.js')
Get-Fix "$Raw/login/switchbot.js" (Join-Path $InstallDir 'server/routes/switchbot.js')
Get-Fix "$Raw/login/Login.js" (Join-Path $InstallDir 'client/src/pages/Login.js')
$desktopPages = Join-Path $InstallDir 'desktop/client/src/pages'
if (Test-Path -LiteralPath $desktopPages -PathType Container) {
    Get-Fix "$Raw/login/Login.js" (Join-Path $desktopPages 'Login.js')
}
Get-Fix "$Raw/login/localVariablesService.js" (Join-Path $InstallDir 'desktop/server/services/localVariablesService.js')
Get-Fix "$Raw/login/localVariablesService.js" (Join-Path $InstallDir 'server/services/localVariablesService.js')

$pkg = Join-Path $InstallDir 'client/package.json'
$py = @'
import json, sys
p = sys.argv[1]
with open(p) as f:
    data = json.load(f)
if data.get("homepage") != ".":
    data["homepage"] = "."
    with open(p, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("-> Set client homepage to .")
else:
    print("-> client homepage already .")
'@
$pyFile = Join-Path ([IO.Path]::GetTempPath()) 'switchbot-homepage.py'
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText($pyFile, $py, $utf8)
& python3 $pyFile $pkg
if ($LASTEXITCODE -ne 0) { Stop-Update 'Could not set client homepage.' }
Remove-Item -LiteralPath $pyFile -Force

$appjs = Join-Path $InstallDir 'client/src/App.js'
$appText = [IO.File]::ReadAllText($appjs)
if ($appText.Contains('BrowserRouter as Router')) {
    $appText = $appText.Replace('BrowserRouter as Router', 'HashRouter as Router')
    [IO.File]::WriteAllText($appjs, $appText, $utf8)
    Write-Host '-> Using HashRouter'
}

Write-Host '-> Installing root dependencies...'
& npm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '-> Installing client dependencies...'
Set-Location -LiteralPath (Join-Path $InstallDir 'client')
& npm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-ClientEnv
Write-Host '-> Building client...'
$env:DISABLE_ESLINT_PLUGIN = 'true'
& npm run build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$index = Get-Content -LiteralPath 'build/index.html' -Raw
if ($index -match 'src="/static/|href="/static/') {
    Stop-Update 'Error: client build still uses /static paths. The window would stay blank.'
}
Write-Host '-> Client build uses relative paths.'
Set-Location -LiteralPath $InstallDir

New-Item -ItemType Directory -Force -Path (Join-Path $InstallDir 'desktop/client') | Out-Null
$link = Join-Path $InstallDir 'desktop/client/build'
$target = Join-Path $InstallDir 'client/build'
if ((Test-Path -LiteralPath $link) -and -not ((Get-Item -LiteralPath $link -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Remove-Item -LiteralPath $link -Recurse -Force
}
if (Get-Command ln -ErrorAction SilentlyContinue) {
    & ln -sfn $target $link
    if ($LASTEXITCODE -ne 0) { Stop-Update 'Could not link the client build.' }
} else {
    if (Test-Path -LiteralPath $link) { Remove-Item -LiteralPath $link -Force }
    New-Item -ItemType SymbolicLink -Path $link -Target $target | Out-Null
}

Write-Host '-> Installing server dependencies...'
Set-Location -LiteralPath (Join-Path $InstallDir 'server')
& npm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location -LiteralPath $InstallDir

Write-Host '-> Installing desktop dependencies...'
Set-Location -LiteralPath (Join-Path $InstallDir 'desktop')
& npm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host '-> Rebuilding native modules for Electron...'
& npm run rebuild
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location -LiteralPath $InstallDir

Write-Host ''
Write-Host '=== Update complete ==='
Write-Host "Location: $InstallDir"
Write-Host 'Stop the app if it is open, then:'
Write-Host "  cd $InstallDir/desktop && npm start"
$logHome = if ($env:HOME) { $env:HOME } else { $HomeDir }
Write-Host "Debug log: $logHome/.config/switchbot/switchbot-debug.log"
