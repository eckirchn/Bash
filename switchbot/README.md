SwitchBot desktop fixes for a local checkout at ~/SwitchBot-App.

From anywhere, after this script is in ~/bin:

    SwitchBot_Update

That fast-forwards the git checkout when it can, applies the Linux window
fix and two-step email login from this directory, and rebuilds the app.
Stop the app first. Then: cd ~/SwitchBot-App/desktop && npm start

The first time, save switchbot/SwitchBot_Update as ~/bin/SwitchBot_Update
and chmod +x it. Later runs replace that file from GitHub by themselves.
