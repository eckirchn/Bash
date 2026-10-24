# sshkeygen

Updated: 24 October 2026, 3:24 AM MDT

The same script is in the public bin repository: `https://github.com/eckirchn/bin`

Makes one SSH key for one server, writes a `Host` block at the top of `~/.ssh/config`, and tries to install the public key.

Use it from current Fedora, Ubuntu, Raspberry Pi OS, Git Bash, or Windows PowerShell. The server side of the copy is current Fedora, Ubuntu, or Raspberry Pi OS. It does not set up a Windows SSH server.

The 2019 script is kept as [archive/sshkeygen-20190126](../archive/sshkeygen-20190126). Do not run that copy. It required `fpaste`, which Ubuntu and Raspberry Pi OS do not install, and it told `sshd` to set `UsePAM no`.

## Run

Linux, Raspberry Pi OS, or Git Bash:

```bash
sshkeygen myserver
sshkeygen -u myuser myserver
sshkeygen -a pishelf -u myuser 192.168.1.20
```

Windows PowerShell:

```powershell
.\sshkeygen.ps1 myserver
.\sshkeygen.ps1 -RemoteUser myuser myserver
.\sshkeygen.ps1 -Alias pishelf -RemoteUser myuser 192.168.1.20
```

If Windows refuses the script:

```powershell
powershell -ExecutionPolicy Bypass -File .\sshkeygen.ps1 myserver
```

`myuser@myserver` is the same as passing the user separately. Give the user only once.

## What you need

| Where you run it | Package or feature |
|---|---|
| Fedora | `sudo dnf install openssh-clients` |
| Ubuntu | `sudo apt install openssh-client` |
| Raspberry Pi OS | `sudo apt install openssh-client` |
| Windows | OpenSSH Client optional feature |

`ssh-copy-id` is used when it exists. Windows does not ship it. The PowerShell script, and the bash script when `ssh-copy-id` is missing, send the public key with `ssh` instead.

Raspberry Pi OS does not listen for SSH until you turn it on:

```bash
sudo systemctl enable --now ssh
```

## What it writes

| Path | What it is |
|---|---|
| `~/.ssh/id_ed25519.myserver` | Private key. An existing file is kept. |
| `~/.ssh/id_ed25519.myserver.pub` | Public key |
| `~/.ssh/config` | Managed block between `# BEGIN sshkeygen myserver` and `# END sshkeygen myserver` |
| `~/.ssh/config.bak` | Previous config, only when a config file was already there |

The block is inserted at the top. SSH uses the first `Host` match. `IdentityFile` is written as `~/.ssh/...` so the same line works on Linux and Windows. `IdentitiesOnly yes` stops SSH from offering your other keys.

A second run does not make a second key and does not duplicate the block. Delete the private key yourself if you want a new one.

## Options

| Option | Bash | PowerShell | Meaning |
|---|---|---|---|
| Alias | `-a pishelf` | `-Alias pishelf` | Name you type after `ssh`. Default is the host. |
| Port | `-p 2222` | `-Port 2222` | Omitted from the config when it is 22. |
| Type | `-t rsa` | `-Type rsa` | Default `ed25519`. `rsa` is 4096 bits. |
| Comment | `-c text` | `-Comment text` | Default is `localuser@thishost`. |
| Passphrase | prompt, or `-N text` | prompt, or `-Passphrase text` | The prompt is the normal path. |
| Empty passphrase | `--empty-passphrase` | `-EmptyPassphrase` | Same as the 2019 script. An unlocked key is easier to steal. |
| No copy | `--no-copy` | `-NoCopy` | Write the key and config only. |

## After the login works

Confirm in a second terminal:

```bash
ssh myserver
```

Only then turn off password login. Do not set `UsePAM no`. On current OpenSSH the keyboard option is `KbdInteractiveAuthentication`. `ChallengeResponseAuthentication` is an old name.

Create `/etc/ssh/sshd_config.d/99-keys-only.conf` on the server:

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
```

Check, then reload:

| Server | Command |
|---|---|
| Fedora | `sudo sshd -t && sudo systemctl reload sshd` |
| Ubuntu | `sudo sshd -t && sudo systemctl reload ssh` |
| Raspberry Pi OS | `sudo sshd -t && sudo systemctl reload ssh` |

The script does not edit `sshd` for you. If the copy fails, it prints the public key and leaves the config entry in place. Nothing is sent to a paste site.
