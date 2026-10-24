# gitBinCreate

Updated: 24 October 2026, 3:14 AM MDT

First checkout of this repo into `$HOME/bin`. It runs [gitBinUpdate](gitBinUpdate.md).

`$HOME/bin` on a machine that only has copied scripts is not a git checkout. `git fetch` there fails with `fatal: not a git repository`. This script turns that directory into a checkout without deleting the scripts that are not in the repo.

It does not read or write `~/.ssh`. It does not run `ssh-keygen`. It does not change an SSH config. The default URL is HTTPS, so a key already on the machine is not offered to GitHub. That includes a key a BirdNET-Pi install may already be using.

## First run

```bash
git clone https://github.com/eckirchn/Bash.git /tmp/Bash
/tmp/Bash/gitBinCreate
```

The repo is private. When git asks:

| Prompt | What to type |
|---|---|
| Username | The GitHub login |
| Password | A personal access token for this repo. Not the GitHub account password. |

On GitHub: Settings, Developer settings, Personal access tokens. A fine-grained token can be limited to this one repo, with Contents set to read. A classic token needs the `repo` scope.

Needs `git`.

| Machine | Install |
|---|---|
| Fedora | `sudo dnf install git` |
| Ubuntu | `sudo apt install git` |
| Raspberry Pi OS | `sudo apt install git` |

## What it changes

| Path | What happens |
|---|---|
| Files in the repo, such as `sshkeygen` | Written, replacing a local file of the same name |
| Files only on this machine | Left in place |
| `$HOME/bin/.git` | Created if it was missing |
| `~/.ssh` | Not touched |
| Git config outside `$HOME/bin` | Not touched |

It does not `git clean`. It does not `git reset --hard`. It does not push, and it does not commit the local scripts. If `$HOME/bin` is already a checkout of a different remote, it stops.

After this, use [gitBinUpdate](gitBinUpdate.md).
