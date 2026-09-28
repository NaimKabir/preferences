#!/bin/bash
# Optional TLA+ support. Run after setup-neovim.sh.
set -euo pipefail
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TLA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/preferences-tlaplus"
for dependency in git cc curl tar nvim; do
  command -v "$dependency" >/dev/null || { printf 'Missing dependency: %s\n' "$dependency" >&2; exit 1; }
done

# Its nested submodules are upstream test fixtures, not runtime dependencies.
git -C "$REPO_PATH" submodule update --init -- \
  nvim/plugins/tree-sitter-tlaplus nvim/plugins/tlaplus-symbols
GRAMMAR="$REPO_PATH/nvim/plugins/tree-sitter-tlaplus"
mkdir -p "$TLA_DIR/parser" "$TLA_DIR/queries/tlaplus"
# Use the generated C parser at the submodule's pinned commit; no npm/CLI needed.
cc -O2 -fPIC -shared -I "$GRAMMAR/src" \
  "$GRAMMAR/src/parser.c" "$GRAMMAR/src/scanner.c" -o "$TLA_DIR/parser/tlaplus.so"
cp "$GRAMMAR/queries/highlights.scm" "$TLA_DIR/queries/tlaplus/highlights.scm"

if [ -n "${TLAPM_LSP:-}" ]; then
  "$TLAPM_LSP" --help=plain >/dev/null
elif command -v tlapm_lsp >/dev/null 2>&1; then
  tlapm_lsp --help=plain >/dev/null
elif [ ! -x "$TLA_DIR/tlapm/bin/tlapm_lsp" ]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) platform=arm64-darwin ;;
    Linux-x86_64) platform=x86_64-linux-gnu ;;
    *) printf 'No upstream binary for this platform. Build TLAPS and set TLAPM_LSP to its tlapm_lsp executable; see README.md.\nSyntax highlighting is installed.\n' >&2; exit 1 ;;
  esac
  staging="$(mktemp -d)"
  trap 'rm -rf "$staging"' EXIT
  archive="${TLAPM_ARCHIVE:-$staging/tlapm.tar.gz}"
  if [ -z "${TLAPM_ARCHIVE:-}" ]; then
    printf 'Downloading the upstream TLAPS rolling prerelease (~1 GB); this is only needed once.\n'
    curl -fL --retry 3 --output "$archive" \
      "https://github.com/tlaplus/tlapm/releases/download/1.6.0-pre/tlapm-1.6.0-pre-$platform.tar.gz"
  fi
  # Install the LSP, CLI, and standard modules. Bundled proof backends such as
  # Isabelle are not needed for editing and are intentionally not extracted.
  tar -xzf "$archive" -C "$staging" tlapm/bin tlapm/lib/tlapm/stdlib
  "$staging/tlapm/bin/tlapm_lsp" --help=plain >/dev/null
  mkdir -p "$TLA_DIR/tlapm"
  cp -R "$staging/tlapm/." "$TLA_DIR/tlapm/"
  "$TLA_DIR/tlapm/bin/tlapm" --version > "$TLA_DIR/installed-version.txt"
fi
printf 'TLA+ syntax and language server installed. Restart Neovim and open a .tla file.\n'
