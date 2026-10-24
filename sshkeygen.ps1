#Requires -Version 5.1
<#
Updated: 24 October 2026, 2:36 AM MDT
sshkeygen.ps1 — Windows companion to sshkeygen.

Clients: Windows PowerShell 5.1 and PowerShell 7, with the OpenSSH Client feature.
Servers: current Fedora, Ubuntu, and Raspberry Pi OS.
Git Bash on Windows can run the bash script instead.

The 2019 script required fpaste, wrote an empty-passphrase RSA key, and told
sshd to set UsePAM no. This script does none of that.
#>

param(
    [Parameter(Position = 0)]
    [string]$HostName,
    [Parameter(Position = 1)]
    [string]$PositionalUser,
    [string]$Alias,
    [int]$Port = 22,
    [ValidateSet("ed25519", "rsa", "ED25519", "RSA")]
    [string]$Type = "ed25519",
    [string]$Comment,
    [string]$RemoteUser,
    [string]$Passphrase,
    [switch]$EmptyPassphrase,
    [switch]$NoCopy,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Revision = "20261024_0236"

function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor White }
function Write-Good([string]$Message) { Write-Host $Message -ForegroundColor Green }
function Write-Warn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Bad([string]$Message) { Write-Host $Message -ForegroundColor Red }
function Write-Accent([string]$Message) { Write-Host $Message -ForegroundColor Cyan }

function Show-Usage {
    @"
Usage: sshkeygen.ps1 [options] <host> [remote-user]

  host            Server name or address. myuser@myserver is allowed.
  remote-user     Account on the server. Default: your Windows user name.

Options:
  -Alias NAME            Host alias in ~/.ssh/config (default: the host)
  -Port PORT             Remote SSH port (default: 22)
  -Type TYPE             ed25519 (default) or rsa
  -Comment TEXT          Key comment (default: localuser@thishost)
  -RemoteUser NAME       Same as remote-user
  -Passphrase TEXT       Set a passphrase. Prefer the prompt instead.
  -EmptyPassphrase       No passphrase (the 2019 behavior)
  -NoCopy                Write the key and config only. Do not contact the server.
  -Help

Examples:
  .\sshkeygen.ps1 myserver
  .\sshkeygen.ps1 -RemoteUser myuser myserver
  .\sshkeygen.ps1 -Alias pishelf -RemoteUser myuser 192.168.1.20
  .\sshkeygen.ps1 -EmptyPassphrase -Type rsa myserver

If Windows blocks the script:
  powershell -ExecutionPolicy Bypass -File .\sshkeygen.ps1 myserver
"@
}

function ConvertTo-ShSingleQuoted([string]$Text) {
    return "'" + ($Text -replace "'", "'\''") + "'"
}

function Test-Token([string]$Text) {
    return $Text -match '^[A-Za-z0-9][A-Za-z0-9._-]{0,253}$'
}

function Test-UserName([string]$Text) {
    return $Text -match '^[A-Za-z_][A-Za-z0-9._-]{0,31}$'
}

function Get-MarkerLinePresent([string]$Path, [string]$Needle) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if ($line.TrimEnd("`r") -eq $Needle) { return $true }
    }
    return $false
}

function Test-HostOutsideBlock([string]$Path, [string]$Alias) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $begin = "# BEGIN sshkeygen $Alias"
    $end = "# END sshkeygen $Alias"
    $skip = $false
    foreach ($raw in @(Get-Content -LiteralPath $Path)) {
        $line = $raw.TrimEnd("`r")
        if ($line -eq $begin) { $skip = $true; continue }
        if ($skip) {
            if ($line -eq $end) { $skip = $false }
            continue
        }
        if ($line -match '^Host\s+(.*)$') {
            $names = $Matches[1] -split '\s+'
            foreach ($name in $names) {
                if ($name -eq $Alias) { return $true }
            }
        }
    }
    return $false
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Update-SshConfig([string]$Path, [string]$Alias, [string[]]$BlockLines) {
    $begin = "# BEGIN sshkeygen $Alias"
    $end = "# END sshkeygen $Alias"
    $lines = @()
    if (Test-Path -LiteralPath $Path) {
        $lines = @(Get-Content -LiteralPath $Path | ForEach-Object { $_.TrimEnd("`r") })
    }
    if ((Get-MarkerLinePresent $Path $begin) -and -not (Get-MarkerLinePresent $Path $end)) {
        throw "SSH config has $begin but no matching end marker. Fix $Path by hand."
    }
    $out = New-Object System.Collections.Generic.List[string]
    if (Get-MarkerLinePresent $Path $begin) {
        Copy-Item -LiteralPath $Path -Destination ($Path + ".bak") -Force
        $skip = $false
        foreach ($line in $lines) {
            if ($line -eq $begin) {
                foreach ($blockLine in $BlockLines) { $out.Add($blockLine) }
                $skip = $true
                continue
            }
            if ($skip) {
                if ($line -eq $end) { $skip = $false }
                continue
            }
            $out.Add($line)
        }
    }
    else {
        if (Test-Path -LiteralPath $Path) {
            Copy-Item -LiteralPath $Path -Destination ($Path + ".bak") -Force
        }
        foreach ($blockLine in $BlockLines) { $out.Add($blockLine) }
        if ($lines.Count -gt 0) {
            $out.Add("")
            foreach ($line in $lines) { $out.Add($line) }
        }
    }
    $text = ($out.ToArray() -join "`n") + "`n"
    Write-Utf8NoBom $Path $text
}

function New-ConfigBlock([string]$Alias, [string]$HostName, [string]$UserName, [int]$Port, [string]$Identity) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("# BEGIN sshkeygen $Alias")
    $lines.Add("Host $Alias")
    $lines.Add("  HostName $HostName")
    $lines.Add("  User $UserName")
    if ($Port -ne 22) { $lines.Add("  Port $Port") }
    $lines.Add("  IdentityFile $Identity")
    $lines.Add("  IdentitiesOnly yes")
    $lines.Add("# END sshkeygen $Alias")
    return $lines.ToArray()
}

function Show-ServerReminder([string]$Alias) {
    Write-Host ""
    Write-Info "In a second terminal, confirm the key works before you change the server:"
    Write-Warn "  ssh $Alias"
    Write-Host ""
    Write-Info "Password login can be turned off after that. Do not set UsePAM no."
    Write-Info "On current Fedora, Ubuntu, and Raspberry Pi OS, add"
    Write-Info "/etc/ssh/sshd_config.d/99-keys-only.conf with:"
    Write-Warn "  PasswordAuthentication no"
    Write-Warn "  KbdInteractiveAuthentication no"
    Write-Warn "  PubkeyAuthentication yes"
    Write-Host ""
    Write-Info "Check the config, then reload:"
    Write-Warn "  Fedora:           sudo sshd -t && sudo systemctl reload sshd"
    Write-Warn "  Ubuntu:           sudo sshd -t && sudo systemctl reload ssh"
    Write-Warn "  Raspberry Pi OS:  sudo sshd -t && sudo systemctl reload ssh"
    Write-Host ""
    Write-Info "Raspberry Pi OS does not listen for SSH until you enable it:"
    Write-Warn "  sudo systemctl enable --now ssh"
}

function Show-ManualInstall([string]$PubPath, [string]$UserName, [string]$HostName, [int]$Port) {
    $shown = (Get-Content -LiteralPath $PubPath -Raw).Trim()
    Write-Host ""
    Write-Bad "Could not install the key automatically."
    Write-Info "The key and the SSH config entry are already on this machine."
    Write-Info "Public key:"
    Write-Host ""
    Write-Accent $shown
    Write-Host ""
    Write-Info "On the server, as $UserName, append that one line to ~/.ssh/authorized_keys"
    Write-Info "Permissions on the server:"
    Write-Warn "  chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
    if ($Port -eq 22) {
        Write-Warn "  ssh-copy-id -i `"$PubPath`" ${UserName}@${HostName}"
    }
    else {
        Write-Warn "  ssh-copy-id -p $Port -i `"$PubPath`" ${UserName}@${HostName}"
    }
}

if ($Help -or $HostName -eq "-Help" -or $HostName -eq "--help" -or $HostName -eq "-h") {
    Show-Usage
    exit 0
}

Write-Info "Script Revision:  $Revision"
Write-Host "  Windows OpenSSH client. Servers: Fedora, Ubuntu, Raspberry Pi OS." -ForegroundColor Magenta
Write-Host ""

if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    Write-Bad "missing: ssh-keygen"
    Write-Warn "Install the OpenSSH Client feature, then open a new PowerShell window:"
    Write-Warn "  Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
    exit 1
}
if (-not $NoCopy -and -not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    Write-Bad "missing: ssh"
    Write-Warn "Install the OpenSSH Client feature, then open a new PowerShell window:"
    Write-Warn "  Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
    exit 1
}
Write-Good "  ssh-keygen: OK"
Write-Host ""

if (-not $HostName) {
    Show-Usage
    Write-Bad "Give a host name."
    exit 1
}

if ($EmptyPassphrase -and $PSBoundParameters.ContainsKey("Passphrase")) {
    Write-Bad "Use either -EmptyPassphrase or -Passphrase, not both."
    exit 1
}

$Type = $Type.ToLowerInvariant()

if ($Port -lt 1 -or $Port -gt 65535) {
    Write-Bad "Port must be 1-65535."
    exit 1
}

if ($HostName -match '@.*@' -or $HostName.StartsWith("@") -or $HostName.EndsWith("@")) {
    Write-Bad "Host must look like myserver or myuser@myserver."
    exit 1
}

$embeddedUser = ""
if ($HostName -match '^([^@]+)@([^@]+)$') {
    $embeddedUser = $Matches[1]
    $HostName = $Matches[2]
}

if ($RemoteUser -and $PositionalUser -and $RemoteUser -ne $PositionalUser) {
    Write-Bad "Remote user was given twice."
    exit 1
}
if (-not $RemoteUser) { $RemoteUser = $PositionalUser }
if ($RemoteUser -and $embeddedUser -and $RemoteUser -ne $embeddedUser) {
    Write-Bad "Remote user was given twice."
    exit 1
}
if (-not $RemoteUser) { $RemoteUser = $embeddedUser }
if (-not $RemoteUser) { $RemoteUser = $env:USERNAME }

if (-not (Test-Token $HostName)) {
    Write-Bad "Host may only use letters, numbers, dots, underscores, and hyphens."
    exit 1
}
if (-not (Test-UserName $RemoteUser)) {
    Write-Bad "Remote user is not a normal account name."
    exit 1
}
if (-not $Alias) { $Alias = $HostName }
if (-not (Test-Token $Alias)) {
    Write-Bad "Alias may only use letters, numbers, dots, underscores, and hyphens."
    exit 1
}

if (-not $Comment) {
    $Comment = "$($env:USERNAME)@$($env:COMPUTERNAME)"
}
if ($Comment.Contains("`n") -or $Comment.Contains("`r")) {
    Write-Bad "Comment cannot contain a newline."
    exit 1
}

$promptOk = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
if (-not $EmptyPassphrase -and -not $PSBoundParameters.ContainsKey("Passphrase") -and -not $promptOk) {
    Write-Bad "No terminal for a passphrase prompt. Pass -EmptyPassphrase or -Passphrase."
    exit 1
}

if ($RemoteUser -eq "root") {
    Write-Warn "Remote user is root. A normal account is safer."
    Write-Host ""
}

$sshDir = Join-Path $env:USERPROFILE ".ssh"
if (-not (Test-Path -LiteralPath $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

$keyName = "id_{0}.{1}" -f $Type, $Alias
$keyPath = Join-Path $sshDir $keyName
$pubPath = "$keyPath.pub"
$identity = "~/.ssh/$keyName"
$configPath = Join-Path $sshDir "config"

if (Test-Path -LiteralPath $keyPath) {
    Write-Warn "Key exists. Using existing key."
    Write-Accent "  $keyPath"
    if (-not (Test-Path -LiteralPath $pubPath)) {
        Write-Bad "Private key exists but $pubPath does not."
        exit 1
    }
    Write-Host ""
}
else {
    Write-Info "Creating $Type key $keyPath"
    if (-not $EmptyPassphrase -and -not $PSBoundParameters.ContainsKey("Passphrase")) {
        Write-Info "ssh-keygen will ask for a passphrase twice. A blank entry means no passphrase."
        Write-Info "To skip the prompt next time, pass -EmptyPassphrase."
        Write-Host ""
    }
    $genArgs = @("-t", $Type, "-C", $Comment, "-f", $keyPath)
    if ($Type -eq "rsa") { $genArgs += @("-b", "4096") }
    if ($EmptyPassphrase) {
        $genArgs += @("-N", "")
    }
    elseif ($PSBoundParameters.ContainsKey("Passphrase")) {
        $genArgs += @("-N", $Passphrase)
    }
    & ssh-keygen.exe @genArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Bad "ssh-keygen failed. No config change was kept for this host."
        exit 1
    }
    Write-Host ""
}

if (Test-HostOutsideBlock $configPath $Alias) {
    Write-Warn "An older Host $Alias entry is in $configPath."
    Write-Warn "The managed block is placed first, and SSH uses that one."
    Write-Host ""
}

$block = New-ConfigBlock $Alias $HostName $RemoteUser $Port $identity
Update-SshConfig $configPath $Alias $block
Write-Good "SSH config updated: $configPath"
Write-Host ""

if ($NoCopy) {
    Write-Info "Skipped the copy to the server."
    Show-ServerReminder $Alias
    exit 0
}

Write-Good "Installing the public key for ${RemoteUser}@${HostName}"
$pubLine = (Get-Content -LiteralPath $pubPath -Raw).Trim()
$quoted = ConvertTo-ShSingleQuoted $pubLine
$remote = "umask 077; mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF $quoted ~/.ssh/authorized_keys || printf '%s\n' $quoted >> ~/.ssh/authorized_keys"
$sshArgs = @(
    "-p", "$Port",
    "-o", "PreferredAuthentications=publickey,password,keyboard-interactive",
    "-o", "ConnectTimeout=15",
    "${RemoteUser}@${HostName}",
    $remote
)
& ssh.exe @sshArgs
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Good "Key installed."
    Show-ServerReminder $Alias
    exit 0
}

Show-ManualInstall $pubPath $RemoteUser $HostName $Port
Show-ServerReminder $Alias
exit 2
