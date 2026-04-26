#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-for-project.sh <target-project> [install-subdir]

Copies this agent-browser checkout into a target project and performs a basic setup.

Arguments:
  target-project   Existing project directory that will receive the copy
  install-subdir   Relative path inside the target project
                   Default: tools/agent-browser
EOF
}

copy_with_rsync() {
  rsync -a \
    --exclude '.git/' \
    --exclude '.codex' \
    --exclude '.claude-plugin/' \
    --exclude 'node_modules/' \
    --exclude 'cli/target/' \
    --exclude 'packages/dashboard/node_modules/' \
    --exclude 'packages/dashboard/.next/' \
    --exclude 'docs/.next/' \
    "$SOURCE_ROOT/" "$DEST/"
}

copy_with_tar() {
  tar -C "$SOURCE_ROOT" \
    --exclude='.git' \
    --exclude='.codex' \
    --exclude='.claude-plugin' \
    --exclude='node_modules' \
    --exclude='cli/target' \
    --exclude='packages/dashboard/node_modules' \
    --exclude='packages/dashboard/.next' \
    --exclude='docs/.next' \
    -cf - . | tar -C "$DEST" -xf -
}

copy_repo() {
  if command -v rsync >/dev/null 2>&1; then
    copy_with_rsync
  else
    copy_with_tar
  fi
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: node is required to run agent-browser." >&2
  exit 1
fi

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_INPUT="$1"
INSTALL_SUBDIR="${2:-tools/agent-browser}"

if [[ ! -d "$TARGET_INPUT" ]]; then
  echo "Error: target project does not exist: $TARGET_INPUT" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "$TARGET_INPUT" && pwd)"
DEST="$TARGET_PROJECT/$INSTALL_SUBDIR"

case "$DEST" in
  "$SOURCE_ROOT" | "$SOURCE_ROOT"/*)
    echo "Error: destination must be outside the source checkout." >&2
    exit 1
    ;;
esac

if [[ -d "$DEST" ]] && find "$DEST" -mindepth 1 -maxdepth 1 | read -r _; then
  echo "Error: destination already exists and is not empty: $DEST" >&2
  echo "Choose another install path or remove the existing directory first." >&2
  exit 1
fi

mkdir -p "$DEST"

echo "Copying agent-browser to $DEST"
copy_repo

chmod +x "$DEST/bin/agent-browser.js" 2>/dev/null || true
find "$DEST/bin" -maxdepth 1 -type f -name 'agent-browser-*' ! -name '*.js' -exec chmod +x {} +

if node "$DEST/bin/agent-browser.js" --help >/dev/null 2>&1; then
  echo "Native binary is already available in the copied checkout."
else
  if ! command -v pnpm >/dev/null 2>&1; then
    echo "Error: pnpm is required when the copied checkout needs to fetch a native binary." >&2
    exit 1
  fi

  echo "Native binary is not ready in the copied checkout. Running pnpm install."
  (
    cd "$DEST"
    pnpm install
  )
fi

browser_ready=0

if [[ "$(uname -s)" == "Linux" ]]; then
  echo "Installing Chrome for Testing with Linux system dependencies."
  if (
    cd "$DEST"
    ./bin/agent-browser.js install --with-deps
  ); then
    browser_ready=1
  else
    echo ""
    echo "Automatic Linux browser setup did not complete."
    echo "Retry inside the copied checkout when package manager and network access are available:"
    echo "  cd \"$DEST\""
    echo "  ./bin/agent-browser.js install --with-deps"
    echo ""
    echo "If Chrome or Chromium is already installed on the system, agent-browser can use it automatically."
  fi
else
  echo "Installing Chrome for Testing."
  if (
    cd "$DEST"
    ./bin/agent-browser.js install
  ); then
    browser_ready=1
  else
    echo ""
    echo "Automatic browser install did not complete."
    echo "Retry inside the copied checkout when network access is available:"
    echo "  cd \"$DEST\""
    echo "  ./bin/agent-browser.js install"
  fi
fi

echo ""
echo "agent-browser copied to: $DEST"
echo "Run it with:"
echo "  $DEST/bin/agent-browser.js open https://example.com"
echo "  $DEST/bin/agent-browser.js snapshot -i"
echo "  $DEST/bin/agent-browser.js close"

if [[ $browser_ready -eq 0 ]]; then
  echo ""
  echo "Browser install is still pending."
fi
