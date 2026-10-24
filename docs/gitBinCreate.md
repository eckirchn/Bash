# gitBinCreate

Updated: 24 October 2026, 2:55 AM MDT

First checkout of this repo into `$HOME/bin`. It runs [gitBinUpdate](gitBinUpdate.md).

`$HOME/bin` on a machine that only has copied scripts is not a git checkout. `git fetch` there fails with `fatal: not a git repository`. This script turns that directory into a checkout without deleting the scripts that are not in the repo.

## First run

The script has to come from somewhere before `$HOME/bin` is a checkout. Clone to a temp directory, then run it:

```bash
git clone git@github.com:eckirchn/Bash.git /tmp/Bash
/tmp/Bash/gitBinCreate
```

If this machine cannot use GitHub over SSH:

```bash
GIT_BIN_REMOTE=https://github.com/eckirchn/Bash.git /tmp/Bash/gitBinCreate
```

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

It does not `git clean`. It does not `git reset --hard`. It does not push, and it does not commit the local scripts.

After this, use [gitBinUpdate](gitBinUpdate.md).
