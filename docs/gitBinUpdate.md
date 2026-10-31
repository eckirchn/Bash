# gitBinUpdate

Updated: 31 October 2026, 1:15 AM MDT

Refreshes repo files in a `$HOME/bin` that is already a checkout. Files that are not in the repo are left in place.

Before a file that is in the repo is replaced, any local copy whose content or mode differs is renamed to `<name>.YYYYMMDD_HHMMSS` (Mountain Time). Identical files are left alone until the checkout step.

After the files are written, any file that starts with a shebang (`#!`) is made executable. This restores the `+x` bit even when the tree mode in the repository is `100644`.

It fetches the public repository over HTTPS. No login and no SSH key are required. If the origin is still the SSH form of this repository, the script rewrites it to HTTPS.

It does not create a checkout. It does not read or write `~/.ssh`, and it does not change which SSH key a machine uses for GitHub.

The previous version that kept an existing SSH origin is archived as `archive/gitBinUpdate-owner`.

## Install

```bash
git clone https://github.com/eckirchn/Bash.git "$HOME/bin"
```

No login. Needs `git`.

| Machine | Install |
|---|---|
| Fedora | `sudo dnf install git` |
| Ubuntu | `sudo apt install git` |
| Raspberry Pi OS | `sudo apt install git` |

## Run

```bash
gitBinUpdate
```

Another directory:

```bash
gitBinUpdate "$HOME/bin"
```

If that directory is not a checkout of this repository, the script stops. It does not run `git init`.

## What it will and will not do

| | |
|---|---|
| Replace `sshkeygen` with the repo copy | Yes |
| Archive a differing local `sshkeygen` as `sshkeygen.20261031_011545` | Yes |
| Restore `+x` on a shebang script after checkout | Yes |
| Leave a local script such as `myLocalScript` alone | Yes |
| Delete a file that is not in the repo | No |
| Keep a local edit to a file that is in the repo under the original name | No. The repo copy wins; the old one is archived with a timestamp. |
| Commit or push what is only on this machine | No |
| Create a checkout | No |
| Change SSH keys or SSH config | No |
| Change git settings outside this directory | No |
| Rewrite an SSH origin of this repository to HTTPS | Yes |
| Take over a checkout of a different remote | No |

A file removed from the repo is also left on disk. It is no longer tracked. Delete it yourself if you do not want it. Archived timestamped copies stay until you remove them.
