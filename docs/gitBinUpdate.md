# gitBinUpdate

Updated: 24 October 2026, 3:14 AM MDT

Writes the current repo files into `$HOME/bin` over HTTPS. Files that are not in the repo are left in place.

If `$HOME/bin` is not a checkout yet, this does the same job as [gitBinCreate](gitBinCreate.md).

It does not read or write `~/.ssh`, and it does not change which SSH key a machine uses for GitHub.

## Run

```bash
gitBinUpdate
```

Another directory:

```bash
gitBinUpdate "$HOME/bin"
```

## What it will and will not do

| | |
|---|---|
| Replace `sshkeygen` with the repo copy | Yes |
| Leave a local script such as `myLocalScript` alone | Yes |
| Delete a file that is not in the repo | No |
| Keep a local edit to a file that is in the repo | No. The repo copy wins. |
| Commit or push what is only on this machine | No |
| Change SSH keys or SSH config | No |
| Change git settings outside this directory | No |
| Take over a checkout that tracks a different remote | No. It stops. |

A file removed from the repo on GitHub is also left on disk. It is no longer tracked. Delete it yourself if you do not want it.

## If git asks for a password

Username is the GitHub login. Password is a personal access token, not the account password. A fine-grained token can be limited to this repo with Contents set to read.
