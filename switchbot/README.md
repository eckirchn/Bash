SwitchBot desktop fixes for a local checkout at ~/SwitchBot-App.

Stop the app, then from anywhere:

    curl -fsSL https://raw.githubusercontent.com/eckirchn/Bash/main/switchbot/Switchbot_Update.sh | bash

That overlays the Linux window fix and two-step email login, then rebuilds the client.
Restart with: cd ~/SwitchBot-App/desktop && npm start

This GitHub connection can commit here. It cannot commit to eckirchn/SwitchBot-App until that fork is added to the Grok GitHub App (https://github.com/settings/installations).
