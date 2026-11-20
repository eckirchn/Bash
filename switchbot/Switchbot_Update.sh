#!/usr/bin/env bash
# Pull SwitchBot fixes from https://github.com/eckirchn/Bash and apply them
# to ~/SwitchBot-App. Run from anywhere. Do not run this with sudo.
set -euo pipefail

RAW="${SWITCHBOT_RAW:-https://raw.githubusercontent.com/eckirchn/Bash/main/switchbot}"
INSTALL_DIR="${SWITCHBOT_HOME:-${HOME}/SwitchBot-App}"

if [[ "${SWITCHBOT_UPDATE_INNER:-}" != 1 ]]; then
  tmp="$(mktemp)"
  curl -fsSL "${RAW}/Switchbot_Update.sh" -o "${tmp}"
  chmod +x "${tmp}"
  SWITCHBOT_UPDATE_INNER=1 exec bash "${tmp}"
fi

echo "=== SwitchBot-App update ==="
echo "Source: ${RAW}"
echo "Install: ${INSTALL_DIR}"

if [[ ! -d "${INSTALL_DIR}/desktop/server/routes" || ! -d "${INSTALL_DIR}/client/src/pages" ]]; then
  echo "Error: ${INSTALL_DIR} is not a SwitchBot-App checkout."
  exit 1
fi
command -v curl >/dev/null 2>&1 || { echo "Error: curl is not installed."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "Error: npm is not installed."; exit 1; }

fetch() {
  local url="$1" dest="$2"
  mkdir -p "$(dirname "${dest}")"
  curl -fsSL "${url}" -o "${dest}"
  echo "→ ${dest}"
}

fetch "${RAW}/desktop/main.js" "${INSTALL_DIR}/desktop/main.js"
fetch "${RAW}/login/switchbot.js" "${INSTALL_DIR}/desktop/server/routes/switchbot.js"
fetch "${RAW}/login/switchbot.js" "${INSTALL_DIR}/server/routes/switchbot.js"
fetch "${RAW}/login/Login.js" "${INSTALL_DIR}/client/src/pages/Login.js"
if [[ -d "${INSTALL_DIR}/desktop/client/src/pages" ]]; then
  fetch "${RAW}/login/Login.js" "${INSTALL_DIR}/desktop/client/src/pages/Login.js"
fi
fetch "${RAW}/login/localVariablesService.js" "${INSTALL_DIR}/desktop/server/services/localVariablesService.js"
fetch "${RAW}/login/localVariablesService.js" "${INSTALL_DIR}/server/services/localVariablesService.js"

if [[ ! -f "${INSTALL_DIR}/client/.env" ]] || ! grep -q '^REACT_APP_SERVER_URL=.' "${INSTALL_DIR}/client/.env"; then
  printf 'REACT_APP_SERVER_URL=http://127.0.0.1:8089\n' > "${INSTALL_DIR}/client/.env"
  echo "→ Wrote client/.env"
fi

echo "→ Building client..."
(cd "${INSTALL_DIR}/client" && npm install && DISABLE_ESLINT_PLUGIN=true npm run build)
mkdir -p "${INSTALL_DIR}/desktop/client"
if [[ -d "${INSTALL_DIR}/desktop/client/build" && ! -L "${INSTALL_DIR}/desktop/client/build" ]]; then
  rm -rf "${INSTALL_DIR}/desktop/client/build"
fi
ln -sfn "${INSTALL_DIR}/client/build" "${INSTALL_DIR}/desktop/client/build"

echo
echo "=== Update complete ==="
echo "Stop the app if it is open, then:"
echo "  cd ${INSTALL_DIR}/desktop && npm start"
echo "Debug log: ${INSTALL_DIR}/desktop/switchbot-debug.log"
