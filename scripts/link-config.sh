# Shared by the installers; existing configs are preserved alongside the link.
link_config() {
  local source="$1" target="$2" backup
  mkdir -p "$(dirname "$target")"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    backup="${target}.backup.$(date +%Y%m%d%H%M%S).$$"
    mv "$target" "$backup"
    printf 'Saved %s to %s\n' "$target" "$backup"
  fi
  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}
