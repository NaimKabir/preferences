# Preferences

Vim, Neovim, tmux, and Aerospace preferences. Neovim shares `vimrc` and the
repo's pinned Airline and Lean syntax plugins. Neovim uses nvim-tree for Git-aware
file browsing and Diffview to inspect changes; Vim keeps NERDTree.

## Fresh-machine install

On macOS, install [Homebrew](https://brew.sh), then:

```sh
brew install git neovim python node
git clone https://github.com/NaimKabir/preferences.git ~/devel/preferences
cd ~/devel/preferences
./setup-neovim.sh
nvim
```

On Debian/Ubuntu:

```sh
sudo apt-get update
sudo apt-get install git neovim python3 python3-venv nodejs npm
git clone https://github.com/NaimKabir/preferences.git ~/devel/preferences
cd ~/devel/preferences
./setup-neovim.sh
nvim
```

Requires **Neovim 0.11+**, **Python 3.9+**, **Node.js 18+** with npm, Git, and Bash.
A current Node.js LTS release is recommended. If your distribution
ships an older Neovim, install a current stable release using the
[official installation instructions](https://github.com/neovim/neovim/blob/master/INSTALL.md)
first. Other Unix systems work with the same script once these dependencies are
installed. Native Windows isn't covered.

The script initializes the required Git submodules, installs Black 25.1.0 into
an isolated virtual environment, Prettier 3.9.8 into a separate npm directory,
installs TypeScript and Python language servers in another isolated npm directory,
and links `~/.config/nvim` to this checkout.
Internet access is needed for installation, but not editor startup. No Python
provider or plugin manager is required. Keep the checkout in place: the config
is symlinked, so edits here take effect next time you launch Neovim.

To also link the Vim, tmux, and Aerospace configs, run `./setup.sh` instead.
It includes Neovim setup and initializes all Vim plugins. It installs configs,
not the Vim/tmux/Aerospace applications. Aerospace is macOS-only. The original
Vim Black plugin is retained for Vim and has its own legacy Python requirements;
the isolated Black installation is for Neovim.

Both installers work from any current directory. `setup.sh /absolute/repo/path`
is also supported for compatibility. Existing files, directories, or symlinks
are moved to `<path>.backup.<timestamp>.<pid>` before replacement. Rerunning is
safe; already-correct links are left alone. The Neovim-only installer does not
change your Vim or other application configs.

## Editor behavior

Edit `vimrc` for shared settings and mappings; edit `nvim/init.lua` for
Neovim-specific behavior. Relative line numbers, syntax highlighting, search
highlighting, backup files, and persistent undo are enabled. Neovim uses the
Dayfox (Nightfox's light variant) with true color enabled and restores the last cursor position when reopening
files.

| Key / command | Action |
| --- | --- |
| `jk` in insert mode | Leave insert mode |
| `Esc Esc` | Clear search highlighting |
| `Ctrl-P` | Locate current file in nvim-tree |
| `Ctrl-H/J/K/L` | Move between splits |
| `Ctrl-Space` / `Ctrl-@` | Exchange windows |
| `Ctrl-C` in normal mode | Close current split |
| Up / Down | Grow / shrink split height |
| Left / Right | Grow / shrink split width |
| `\n` / `:NvimTreeToggle` | Toggle file tree |
| `:Black` | Format current Python buffer, without saving |
| `:Prettier` | Format current JavaScript/TypeScript buffer (including JSX/TSX), without saving |

`:Black` uses the buffer's filename to discover project `pyproject.toml` settings;
formatting errors leave the buffer unchanged. Use normal undo to undo formatting.
The Black version is pinned in `setup-neovim.sh`; change it and rerun to upgrade.
The legacy `:BlackUpgrade` and `:BlackVersion` commands are not provided in Neovim.
`:Prettier` uses the buffer's filename to select a parser and find project
Prettier configuration. For unnamed buffers, set `:set filetype=typescript`
(or `javascript`, `typescriptreact`, `javascriptreact`) first. It uses the
installer's pinned version, not a project's local Prettier, and leaves saving
to you. Errors preserve the buffer; normal undo reverses formatting. Node.js
must be on Neovim's PATH. Change the version in `setup-neovim.sh` and rerun to
upgrade. To add Prettier to an existing install, install Node.js/npm, rerun
`./setup-neovim.sh`, and restart Neovim.

Lean support matches the existing syntax/indentation plugin; it does not install
a Lean toolchain, language server, or proof interface.

Neovim honors `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and `XDG_STATE_HOME`. Defaults:

- Config: `~/.config/nvim` (symlink into this repo).
- Black: `~/.local/share/nvim/preferences-black`.
- Prettier: `~/.local/share/nvim/preferences-prettier`.
- Language servers: `~/.local/share/nvim/preferences-lsp`.
- Backups, swap, undo: separate directories under `~/.local/state/nvim`.

Use the default `NVIM_APPNAME` (`nvim`) with this setup. Terminals or macOS input
shortcuts may intercept Ctrl-Space; Ctrl-@ is mapped to the same action.

## Git tree and change inspection

`./setup-neovim.sh` installs nvim-tree, Diffview, and its Plenary dependency at
commits pinned by Git submodules. Restart Neovim after upgrading an existing
install. No special font is required.

Press `Ctrl-P` to reveal the current file, or `\n` to toggle the tree. Git status
appears beside files and on parent directories: `M` = unstaged changes, `S` =
staged changes, `?` = untracked, `R` = renamed, `D` = deleted, `U` = conflicts.
A file can have both staged and unstaged markers. The tree shows files on disk;
save buffers before inspecting their Git changes. Deleted files can be inspected
in Diffview even though they no longer appear in the file tree.

Inside the tree:

| Key | Action |
| --- | --- |
| Enter / `o` | Open file or expand folder |
| `s` / `i` / `t` | Open in vertical split / horizontal split / new tab |
| `C` | Toggle showing only Git-changed files |
| `]c` / `[c` | Next / previous Git-changed entry |
| `R` | Refresh (status also updates automatically) |
| `I` | Toggle showing Git-ignored files |
| `q` | Close tree |
| `g?` | Show all tree mappings |

To inspect changes with Diffview:

| Key / command | Action |
| --- | --- |
| `\gd` / `:DiffviewOpen` | Inspect unstaged changes, with staged files also listed |
| `\gs` / `:DiffviewOpen --cached` | Inspect staged changes |
| `\gh` / `:DiffviewFileHistory %` | Inspect current file's history |
| `\gq` / `:DiffviewClose` | Close diff view and return to editing |

In Diffview, select a file in the panel and press Enter to see its before/after
diff. Tab / Shift-Tab cycle files, and `]c` / `[c` jump between diff hunks. Press
`q` in a diff or file panel to close the whole Diffview tab, or `g?` for its help.
Use your Ctrl-H/J/K/L mappings to move between panes. Diffview includes staging
and conflict-resolution actions in its help; simply opening it does not stage
or discard anything. `:DiffviewOpen HEAD` compares the working tree against the
last commit, including staged edits. Run it from the project you want to inspect.

The `\` keys use the default leader (backslash). Configuration lives in
`nvim/lua/preferences/git.lua`. Run `./scripts/check-git.sh` to verify tree status
and actual diff contents against a disposable Git repository.

## Definitions, references, and callers

Neovim has a built-in LSP client. Language servers analyze the project and answer
requests such as “where is this defined?” and “who calls this function?”. The
installer now supplies `typescript-language-server` + TypeScript for JS/TS/JSX/TSX,
and Pyright for Python. No additional Neovim plugin or Mason setup is needed.
Exact versions are pinned in `setup-neovim.sh` (the TypeScript server version is
kept compatible with Node 18/20). Use a current Node LTS when setting up a new machine.

For an existing installation:

```sh
./setup-neovim.sh
# Restart Neovim, then open a .ts, .js, .tsx, .jsx, or .py file.
```

Servers start automatically for matching files. Put the cursor on a symbol:

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `grr` | Find references (all uses, not only calls) |
| `\ci` | Incoming calls: functions that call this function |
| `\co` | Outgoing calls: functions called by this function |
| `gri` | Find implementations, when supported |
| `grt` | Go to type definition |
| `K` | Show documentation/type |
| `grn` | Rename symbol across the project |
| `gra` | Available code actions |
| `\e` | Show diagnostic under cursor |
| `Ctrl-O` / `Ctrl-I` | Jump back / forward |
| `Ctrl-X Ctrl-O` in insert mode | Language-server completion |

The `\` bindings use Vim's default leader key; type backslash, then `c`, then
`i` for callers. If you set `mapleader`, use that key instead. Multiple results
appear in the quickfix list: `:copen` opens it, Enter jumps to an item, and
`:cnext` / `:cprev` move through results. Existing Ctrl-Space window exchange
and split-navigation mappings are preserved.

For accurate results:

- **JavaScript/TypeScript:** install the project's dependencies using its usual
  package manager. The server uses `tsconfig.json` / `jsconfig.json` and project
  TypeScript when available, with the installed TypeScript as a fallback. A
  `jsconfig.json` helps define the scope of plain JavaScript projects.
- **Python:** install project dependencies into `.venv`, or activate the desired
  virtual environment before launching Neovim. The setup prefers a root `.venv`,
  then the active environment, then `python3` on PATH. Use `pyrightconfig.json`
  or `[tool.pyright]` in `pyproject.toml` for project-specific analysis settings.
- Project roots are detected from language config/package files, then Git;
  standalone files can also attach. Servers may need a moment to analyze a
  newly opened project. Dynamic calls/reflection can make caller results incomplete.

Run `:checkhealth vim.lsp` to inspect attachment and configuration. If a server
is missing, rerun the installer; if imports are unresolved, check project
dependencies and the Python environment. Run `./scripts/check-lsp.sh` for a
live integration check of cross-file definitions, references, and incoming calls
in both languages. Server configuration and bindings live in
`nvim/lua/preferences/lsp.lua`. Other languages need their own server/config;
Lean remains syntax/indentation-only.

## Verify, update, or remove

```sh
./scripts/check-neovim.sh
```

This runs headless checks against your installed config for mappings, plugins,
Lean file detection, and successful/failed Python and JavaScript/TypeScript formatting. For diagnostics,
run `:checkhealth` inside Neovim. Optional provider warnings do not affect these
plugins. Plugin commits are recorded as Git submodules: after pulling repo
updates, rerun the installer to sync them. It does not track plugin branches.

To remove the setup, unlink `~/.config/nvim` (only if it points here) and restore
any saved backup to that path. The Black, Prettier, and language-server environments can also be removed;
keep the state directory if you want to retain undo history.

References: [Neovim configuration](https://neovim.io/doc/user/starting/),
[Lua API](https://neovim.io/doc/user/lua/),
[Neovim LSP](https://neovim.io/doc/user/lsp/),
[TypeScript language server](https://github.com/typescript-language-server/typescript-language-server),
[Pyright](https://github.com/microsoft/pyright/blob/main/docs/installation.md),
[Prettier CLI](https://prettier.io/docs/cli),
[nvim-tree](https://github.com/nvim-tree/nvim-tree.lua),
[Diffview](https://github.com/sindrets/diffview.nvim), and
[Black CLI](https://black.readthedocs.io/en/stable/usage_and_configuration/the_basics.html).
