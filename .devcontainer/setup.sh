#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- System dependencies ---
sudo apt-get update -qq
sudo apt-get install -y \
  build-essential libssl-dev libreadline-dev zlib1g-dev \
  libffi-dev libyaml-dev libgmp-dev

# --- rbenv + Ruby ---
if [ ! -d "$HOME/.rbenv/.git" ]; then
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
else
  git -C "$HOME/.rbenv" pull
fi
if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
else
  git -C "$HOME/.rbenv/plugins/ruby-build" pull
fi

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

RUBY_VERSION=$(tr -d '[:space:]' < "$WORKSPACE_ROOT/.ruby-version")
if ! rbenv versions --bare | grep -qx "$RUBY_VERSION"; then
  rbenv install "$RUBY_VERSION"
fi
rbenv global "$RUBY_VERSION"
rbenv rehash

# --- nvm + Node.js ---
if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"

NODE_VERSION=$(tr -d '[:space:]' < "$WORKSPACE_ROOT/.node-version")
if [ ! -d "$NVM_DIR/versions/node/v$NODE_VERSION" ]; then
  nvm install "$NODE_VERSION"
fi
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

# Create system-wide symlinks so non-interactive shells (lefthook hooks) can find node/yarn
sudo ln -sf "$NVM_DIR/versions/node/v$NODE_VERSION/bin/node" /usr/local/bin/node
sudo ln -sf "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" /usr/local/bin/npm
sudo ln -sf "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npx" /usr/local/bin/npx
if ! "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" list -g yarn --depth=0 &>/dev/null; then
  "$NVM_DIR/versions/node/v$NODE_VERSION/bin/npm" install -g yarn
fi
sudo ln -sf "$NVM_DIR/versions/node/v$NODE_VERSION/bin/yarn" /usr/local/bin/yarn

# --- Playwright browsers (MCP + system tests) ---
# chromium: used by Playwright MCP server
# chromium-headless-shell: used by capybara-playwright-driver in RSpec system tests
# firefox, webkit: used by pre-push system tests (lefthook)
if ! npx -y playwright --version &>/dev/null; then
  npx -y playwright install chromium chromium-headless-shell firefox webkit --with-deps
else
  npx playwright install chromium chromium-headless-shell firefox webkit --with-deps
fi

# --- Rust + wasi-vfs ---
RUST_VERSION=$(tr -d '[:space:]' < "$WORKSPACE_ROOT/.rust-version")
WASI_VFS_VERSION=$(tr -d '[:space:]' < "$WORKSPACE_ROOT/.wasi-vfs-version")

if [ ! -f "$HOME/.cargo/bin/rustc" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_VERSION"
fi
. "$HOME/.cargo/env"

if ! command -v wasi-vfs &>/dev/null; then
  curl -fsSL "https://github.com/kateinoigakukun/wasi-vfs/releases/download/v${WASI_VFS_VERSION}/wasi-vfs-cli-x86_64-unknown-linux-gnu.zip" -o /tmp/wasi-vfs.zip
  unzip -q /tmp/wasi-vfs.zip -d /tmp/wasi-vfs
  sudo mv /tmp/wasi-vfs/wasi-vfs /usr/local/bin/wasi-vfs
  rm -rf /tmp/wasi-vfs.zip /tmp/wasi-vfs
fi

# --- Google Chrome (for Selenium/Chrome system tests) ---
if ! command -v google-chrome &>/dev/null; then
  curl -fsSL https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/google-chrome.deb
  sudo apt-get install -y /tmp/google-chrome.deb
  rm /tmp/google-chrome.deb
fi

# --- gitleaks (secret scanner used in pre-commit hook) ---
GITLEAKS_VERSION="8.26.0"
if ! command -v gitleaks &>/dev/null; then
  curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
    | sudo tar -xz -C /usr/local/bin gitleaks
fi

# --- Shell profile ---
PROFILE="$HOME/.bashrc"
add_if_missing() {
  grep -qF "$1" "$PROFILE" || echo "$1" >> "$PROFILE"
}

add_if_missing 'export PATH="$HOME/.rbenv/bin:$PATH"'
add_if_missing 'eval "$(rbenv init -)"'
add_if_missing 'export NVM_DIR="$HOME/.nvm"'
add_if_missing '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
add_if_missing '. "$HOME/.cargo/env"'

# --- Claude Code (optional) ---
# To install Claude Code (https://claude.ai/code), create a marker file at the
# workspace root (gitignored, so it's local-only and scoped to this clone):
#   touch .install-claude-code
if [ -f "$WORKSPACE_ROOT/.install-claude-code" ] && ! command -v claude &>/dev/null; then
  sudo mkdir -p "$HOME/.cache/claude"
  sudo chown -R "$USER:$USER" "$HOME/.cache"
  curl -fsSL https://claude.ai/install.sh | bash
fi
