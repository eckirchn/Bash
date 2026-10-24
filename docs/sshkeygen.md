# sshkeygen

Updated: 24 October 2026, 7:23 AM MDT

Revision: 20261024_0440

Run this script on the **client** (the machine that will hold the private key).

It generates one SSH key for one remote server, writes a marked `Host` block at the top of `~/.ssh/config`, and attempts to install the public key on the server. The install step connects to the remote (password prompt on first use if needed).

Empty passphrase is the default.

## Passphrase: blank or set?

- **Leave blank** (default): fully automatic, no prompt on later use. Convenient. The private key file itself is the only protection — anyone who can read it can use it.
- **Set a passphrase** (`-N "yourphrase"`): the key is encrypted. You type the passphrase when the key is first used (or when the agent asks). Better if the machine is shared or the key file might be copied. Slightly less convenient.

Both are valid. Choose based on who else can reach the private key file.

## Example

```text
MyUserName@DellOptiplex:~$ cd bin
MyUserName@DellOptiplex:~/bin$ ./sshkeygen 192.168.89.179
Script Revision:  20261024_0440
  ed25519, Fedora / Ubuntu / Raspberry Pi OS, Git Bash; Windows native is sshkeygen.ps1

Dependency check
  ssh-keygen: OK
  ssh: OK
  ssh-copy-id: OK

Creating ed25519 key /home/MyUserName/.ssh/id_ed25519.192.168.89.179
Using empty passphrase (default).

Generating public/private ed25519 key pair.
Your identification has been saved in /home/MyUserName/.ssh/id_ed25519.192.168.89.179
Your public key has been saved in /home/MyUserName/.ssh/id_ed25519.192.168.89.179.pub
The key fingerprint is:
SHA256:xK9mP2qR7vL4nW8jH3tY6uI1oA5sD0fG+eC8bZ random MyUserName@DellOptiplex
The key's randomart image is:
+--[ED25519 256]--+
|        .o+      |
|       . = o     |
|      . + = .    |
|     . = + .     |
|    . + S o      |
|   . = = .       |
|  . + = .        |
| . o = .         |
|  . .            |
+----[SHA256]-----+

SSH config updated: /home/MyUserName/.ssh/config

Installing the public key for MyUserName@192.168.89.179
...
MyUserName@192.168.89.179's password:

Number of key(s) added: 1

Key installed.

In a second terminal, confirm the key works before you change the server:
  ssh 192.168.89.179
```

## Run

```bash
./sshkeygen 192.168.89.179
./sshkeygen -u MyUserName 192.168.89.179
./sshkeygen -N "myphrase" 192.168.89.179
```

## What it writes on the client

| Path | What it is |
|------|------------|
| `~/.ssh/id_ed25519.192.168.89.179` | Private key |
| `~/.ssh/id_ed25519.192.168.89.179.pub` | Public key |
| `~/.ssh/config` | Managed Host block |

## Options

| Option | Meaning |
|--------|---------|
| `-a`, `--alias NAME` | Host alias |
| `-p`, `--port PORT` | Remote port |
| `-t`, `--type TYPE` | ed25519 (default) or rsa |
| `-u`, `--user NAME` | Remote account |
| `-N`, `--passphrase TEXT` | Set a passphrase |
| `--no-copy` | Skip the remote install |
| `-h`, `--help` | Show usage |

## After the key works

```bash
ssh 192.168.89.179
```

You may then disable password login on the server if desired. The script does not edit `sshd`.

## Notes

- Run on the client. Linux, Raspberry Pi OS, or Git Bash.
- 2019 version archived as `archive/sshkeygen-20190126`.
- `sshkeygen.ps1` is the optional non-Bash Windows companion.
