#!/usr/bin/env bash
# SwitchBot_Update
# Update an existing SwitchBot-App install under $HOME.
# Run from anywhere: SwitchBot_Update
# Do not run the whole script with sudo. sudo is used only for apt.

set -euo pipefail

INSTALL_DIR="${SWITCHBOT_HOME:-${HOME}/SwitchBot-App}"
RAW="${SWITCHBOT_RAW:-https://raw.githubusercontent.com/eckirchn/Bash/main/switchbot}"
SCRIPT_URL="${RAW}/SwitchBot_Update"

# Replace ~/bin/SwitchBot_Update with the copy in GitHub, then run that copy.
if [[ "${SWITCHBOT_UPDATE_INNER:-}" != 1 ]]; then
  tmp="$(mktemp)"
  curl -fsSL "${SCRIPT_URL}" -o "${tmp}"
  mkdir -p "${HOME}/bin"
  cp "${tmp}" "${HOME}/bin/SwitchBot_Update"
  chmod +x "${HOME}/bin/SwitchBot_Update" "${tmp}"
  SWITCHBOT_UPDATE_INNER=1 exec bash "${tmp}"
fi

echo "=== SwitchBot-App update ==="
echo "Install location: ${INSTALL_DIR}"
echo "Fixes from:       ${RAW}"
echo ""

command -v git >/dev/null 2>&1 || { echo "Error: git is not installed."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "Error: npm/node is not installed."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "Error: curl is not installed."; exit 1; }

if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
  echo "Error: ${INSTALL_DIR} is not an existing git checkout."
  echo "Run SwitchBot_Install first."
  exit 1
fi

install_system_deps() {
  local required=(
    build-essential
    python3
    pkg-config
    libudev-dev
    libusb-1.0-0-dev
    libnss3
    libnspr4
    "libatk1.0-0|libatk1.0-0t64"
    "libatk-bridge2.0-0|libatk-bridge2.0-0t64"
    "libcups2|libcups2t64"
    libdrm2
    libgbm1
    "libgtk-3-0|libgtk-3-0t64"
    "libasound2|libasound2t64"
    libxcomposite1
    libxdamage1
    libxfixes3
    libxrandr2
    libxkbcommon0
    libxshmfence1
    libxss1
    libpango-1.0-0
    libcairo2
    libx11-xcb1
  )
  local missing=()
  local spec primary alt

  if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg >/dev/null 2>&1; then
    echo "Error: this script installs system packages with apt."
    echo "Install these packages yourself, then re-run:"
    printf '  %s\n' "${required[@]}"
    exit 1
  fi

  for spec in "${required[@]}"; do
    primary="${spec%%|*}"
    alt=""
    if [[ "${spec}" == *"|"* ]]; then
      alt="${spec#*|}"
    fi
    if dpkg -s "${primary}" >/dev/null 2>&1; then
      continue
    fi
    if [[ -n "${alt}" ]] && dpkg -s "${alt}" >/dev/null 2>&1; then
      continue
    fi
    if [[ -n "${alt}" ]] && apt-cache show "${alt}" >/dev/null 2>&1 && ! apt-cache show "${primary}" >/dev/null 2>&1; then
      missing+=("${alt}")
    else
      missing+=("${primary}")
    fi
  done

  if ((${#missing[@]} == 0)); then
    echo "→ System packages already installed."
    return
  fi

  echo "→ Missing packages: ${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing[@]}"
}

ensure_client_env() {
  local env_file="${INSTALL_DIR}/client/.env"
  local url built
  if [[ -f "${env_file}" ]] && grep -q '^REACT_APP_SERVER_URL=.' "${env_file}"; then
    echo "→ Keeping ${env_file}"
    return
  fi
  url="http://127.0.0.1:8089"
  built=""
  shopt -s nullglob
  local js=( "${INSTALL_DIR}"/client/build/static/js/*.js )
  shopt -u nullglob
  if ((${#js[@]})); then
    built="$(grep -oE 'https?://[^"[:space:]]+:8089' "${js[@]}" | head -1 || true)"
  fi
  if [[ -n "${built}" ]]; then
    url="${built}"
  fi
  printf 'REACT_APP_SERVER_URL=%s\n' "${url}" > "${env_file}"
  echo "→ Wrote ${env_file} (${url})"
}

fetch_fix() {
  local url="$1" dest="$2"
  mkdir -p "$(dirname "${dest}")"
  curl -fsSL "${url}" -o "${dest}"
  echo "→ ${dest}"
}

install_system_deps

cd "${INSTALL_DIR}"
branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${branch}" == "HEAD" ]]; then
  echo "Error: checkout is detached. Check out a branch, then re-run."
  exit 1
fi

# Previous runs of this script edit these files. Put them back to the
# last commit so a fast-forward is not blocked, then re-apply the fixes.
tracked_fixes=(
  desktop/main.js
  desktop/server/routes/switchbot.js
  server/routes/switchbot.js
  client/src/pages/Login.js
  desktop/server/services/localVariablesService.js
  server/services/localVariablesService.js
)
for path in "${tracked_fixes[@]}"; do
  if git cat-file -e "HEAD:${path}" 2>/dev/null; then
    git checkout -- "${path}"
  fi
done

old_rev="$(git rev-parse HEAD)"
echo "→ Fetching origin/${branch}..."
git fetch origin "${branch}"
if git merge --ff-only "origin/${branch}"; then
  new_rev="$(git rev-parse HEAD)"
  if [[ "${old_rev}" == "${new_rev}" ]]; then
    echo "→ Already at ${new_rev:0:7}."
  else
    echo "→ Updated ${old_rev:0:7} -> ${new_rev:0:7}"
    git log --oneline "${old_rev}..${new_rev}"
  fi
else
  echo "→ Could not fast-forward ${branch}. Git history was left as it is."
  echo "→ SwitchBot fixes will still be applied."
fi

echo "→ Applying SwitchBot fixes..."
fetch_fix "${RAW}/desktop/main.js" "${INSTALL_DIR}/desktop/main.js"
fetch_fix "${RAW}/login/switchbot.js" "${INSTALL_DIR}/desktop/server/routes/switchbot.js"
fetch_fix "${RAW}/login/switchbot.js" "${INSTALL_DIR}/server/routes/switchbot.js"
fetch_fix "${RAW}/login/Login.js" "${INSTALL_DIR}/client/src/pages/Login.js"
if [[ -d "${INSTALL_DIR}/desktop/client/src/pages" ]]; then
  fetch_fix "${RAW}/login/Login.js" "${INSTALL_DIR}/desktop/client/src/pages/Login.js"
fi
fetch_fix "${RAW}/login/localVariablesService.js" "${INSTALL_DIR}/desktop/server/services/localVariablesService.js"
fetch_fix "${RAW}/login/localVariablesService.js" "${INSTALL_DIR}/server/services/localVariablesService.js"

echo "→ Installing root dependencies..."
npm install

echo "→ Installing client dependencies..."
cd client
npm install
ensure_client_env
echo "→ Building client..."
DISABLE_ESLINT_PLUGIN=true npm run build
cd "${INSTALL_DIR}"

mkdir -p desktop/client
if [[ -d desktop/client/build && ! -L desktop/client/build ]]; then
  rm -rf desktop/client/build
fi
ln -sfn "${INSTALL_DIR}/client/build" "${INSTALL_DIR}/desktop/client/build"

echo "→ Installing server dependencies..."
cd server
npm install
cd "${INSTALL_DIR}"

echo "→ Installing desktop dependencies..."
cd desktop
npm install
echo "→ Rebuilding native modules for Electron..."
npm run rebuild
cd "${INSTALL_DIR}"

echo ""
echo "=== Update complete ==="
echo "Location: ${INSTALL_DIR}"
echo "Stop the app if it is open, then:"
echo "  cd ${INSTALL_DIR}/desktop && npm start"
echo "Debug log: ${INSTALL_DIR}/desktop/switchbot-debug.log"
