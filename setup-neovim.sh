#!/bin/bash
set -euo pipefail

REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$REPO_PATH/scripts/link-config.sh"

for dependency in git nvim python3 node npm; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'Missing %s. Install prerequisites from README.md, then rerun.\n' "$dependency" >&2
    exit 1
  fi
done
nvim --clean --headless '+lua if vim.fn.has("nvim-0.11") == 0 then vim.cmd("cquit") end' +qa || {
  printf 'Neovim 0.11 or newer is required.\n' >&2
  exit 1
}
python3 -c 'import sys; assert sys.version_info >= (3, 9), "Python 3.9 or newer is required"'
node -e 'if (Number(process.versions.node.split(".")[0]) < 18) { console.error("Node.js 18 or newer is required"); process.exit(1); }'

# Use the commits recorded by this repo, never the latest plugin branches.
git -C "$REPO_PATH" submodule update --init --recursive -- \
  vim/pack/plugins/start/airline \
  vim/pack/plugins/start/lean \
  nvim/plugins/nvim-tree \
  nvim/plugins/plenary \
  nvim/plugins/diffview \
  nvim/plugins/nightfox

BLACK_ENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/preferences-black"
python3 -m venv "$BLACK_ENV"
"$BLACK_ENV/bin/python" -m pip install --disable-pip-version-check 'black==25.1.0'
PRETTIER_ENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/preferences-prettier"
mkdir -p "$PRETTIER_ENV"
npm install --prefix "$PRETTIER_ENV" --no-save --package-lock=false \
  --ignore-scripts --no-audit --no-fund 'prettier@3.9.8'
LSP_ENV="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/preferences-lsp"
mkdir -p "$LSP_ENV"
# Keep a server release compatible with Node 18/20 as well as newer Node LTS.
npm install --prefix "$LSP_ENV" --no-save --package-lock=false \
  --ignore-scripts --no-audit --no-fund \
  'typescript-language-server@4.3.4' 'typescript@5.9.3' 'pyright@1.1.414'
link_config "$REPO_PATH/nvim" "${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
printf '\nNeovim is ready. Use :Black for Python or :Prettier for JavaScript/TypeScript.\n'
printf 'Language servers start automatically for JavaScript, TypeScript, and Python.\n'
