# sshkeygen

Updated: 24 October 2026, 6:57 AM MDT

Revision: 20261024_0440

Run this script on the **client** (the machine that will hold the private key).

It generates one SSH key for one remote server, writes a marked `Host` block at the top of `~/.ssh/config`, and attempts to install the public key on the server. The install step connects to the remote (password prompt on first use if needed).

Empty passphrase is the default (original 2019 automatic behavior).

## Install

Clone the repository wherever you like, then copy the script onto your `PATH`:

```bash
git clone https://github.com/eckirchn/Bash.git
cd Bash
mkdir -p "$HOME/bin"
cp sshkeygen "$HOME/bin/"
chmod +x "$HOME/bin/sshkeygen"
```

Ensure `$HOME/bin` is on your `PATH`, then:

```bash
which sshkeygen
sshkeygen --help
```

## Run (Linux client to Linux server)

```bash
sshkeygen myserver
sshkeygen -u myuser myserver
sshkeygen -a MyAlias -u myuser 192.168.1.20
sshkeygen -N "myphrase" myserver
```

## What it writes on the client

| Path | What it is |
|------|------------|
| `~/.ssh/id_ed25519.myserver` | Private key (empty passphrase by default). Existing key is reused. |
| `~/.ssh/id_ed25519.myserver.pub` | Public key |
| `~/.ssh/config` | Managed block between `# BEGIN sshkeygen …` and `# END sshkeygen …` |

## Options

| Option | Meaning |
|--------|---------|
| `-a`, `--alias NAME` | Host alias (default: the host argument) |
| `-p`, `--port PORT` | Remote port (default 22) |
| `-t`, `--type TYPE` | `ed25519` (default) or `rsa` |
| `-u`, `--user NAME` | Remote account |
| `-N`, `--passphrase TEXT` | Set a passphrase |
| `--no-copy` | Write key and config only |
| `-h`, `--help` | Show usage |

## After the key works

```bash
ssh myserver
```

You may then disable password login on the server if desired. The script does not edit `sshd`.

## Notes

- Linux client to Linux server. Git Bash also works.
- 2019 version archived as `archive/sshkeygen-20190126`.
- `sshkeygen.ps1` is the optional non-Bash Windows companion.
