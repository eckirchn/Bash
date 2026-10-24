# gitBinUpdate

Updated: 24 October 2026, 6:22 AM MDT

Refreshes repo files in a `$HOME/bin` that is already a checkout. Files that are not in the repo are left in place.

It does not create a checkout. The first install is the git commands in the [README](../README.md). The origin URL already set is kept. An SSH checkout stays on SSH.

It does not read or write `~/.ssh`, and it does not change which SSH key a machine uses for GitHub.

## Install

Empty directory:

```bash
git clone '<repository-url>' "$HOME/bin"
```

Directory that already has local scripts:

```bash
cd "$HOME/bin"
git init -b main
git remote add origin '<repository-url>'
git fetch origin main
git checkout -f origin/main -- .
git reset --mixed origin/main
```

`<repository-url>` is the clone URL for this repository. No login is required while the repository is public. Needs `git`.

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

If that directory is not a checkout, the script stops. It does not run `git init`.

## What it will and will not do

| | |
|---|---|
| Replace `sshkeygen` with the repo copy | Yes |
| Leave a local script such as `myLocalScript` alone | Yes |
| Delete a file that is not in the repo | No |
| Keep a local edit to a file that is in the repo | No. The repo copy wins. |
| Commit or push what is only on this machine | No |
| Create a checkout | No |
| Change SSH keys or SSH config | No |
| Change git settings outside this directory | No |
| Take over a checkout of a different remote | No, if `GIT_BIN_REMOTE` is set to the expected URL. If it is unset, the origin already there is used. |

A file removed from the repo is also left on disk. It is no longer tracked. Delete it yourself if you do not want it.
