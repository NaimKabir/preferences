#!/bin/bash
set -euo pipefail
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PREFERENCES_CHECK="$REPO_PATH/scripts/check-neovim.lua" nvim --headless -i NONE \
  '+lua local ok, err = pcall(dofile, vim.env.PREFERENCES_CHECK); if not ok then print(err); vim.cmd("cquit") end' \
  '+qa!'
