#!/bin/bash
set -euo pipefail

# Optional repo path retained for compatibility with the original installer.
REPO_PATH="$(cd "${1:-$(dirname "${BASH_SOURCE[0]}")}" && pwd -P)"
source "$REPO_PATH/scripts/link-config.sh"

bash "$REPO_PATH/setup-neovim.sh"
git -C "$REPO_PATH" submodule update --init --recursive -- vim/pack/plugins/start
mkdir -p "$HOME/vimtmp"
link_config "$REPO_PATH/tmux.conf" "$HOME/.tmux.conf"
link_config "$REPO_PATH/vimrc" "$HOME/.vimrc"
link_config "$REPO_PATH/vim" "$HOME/.vim"
link_config "$REPO_PATH/aerospace.toml" "$HOME/.aerospace.toml"
