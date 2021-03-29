" Enable syntax highlighting
syntax enable
" Enable line numbers
set number
" Setting backup and swap dirs to be vimtmp.
" The double-/ means that files will be stored with fully qualified path
" (in case the files have the same name). The `,.` allows vim to use current
" dir if vimtmp doesn't exist.
set backupdir=~/vimtmp//,.
set directory=~/vimtmp//,.
set undodir=~/vimtmp//,.

" KEYBIND SWAPS

" Map Esc-Esc to clearing highlights
nnoremap <esc><esc> :noh<return>

" Map <C-P> to find files in tree. This overrides a default command
" that's the same as 'k', so no worries.
nnoremap <C-P> :NERDTreeFind<CR>

" Swap out window navigation commands with Mac friendly ones.
" Swapping ctrl-W prepends for window down/up/left/right with
" raw ctrl-J, ctrl-K, etc. 
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l
nnoremap <C-H> <C-W>h
" Swapping out window close command
nnoremap <C-C> <C-W>c

" Window resize commands with arrow keys
nnoremap <Up> :res +1<CR>
nnoremap <Down> :res -1<CR>
nnoremap <Left> :vertical res +1<CR>
nnoremap <Right> :vertical res -1<CR>


" Enabling unix startup script

" When started as "evim", evim.vim will already have done these settings, bail
" out.
if v:progname =~? "evim"
  finish
endif

" Get the defaults that most users want.
source $VIMRUNTIME/defaults.vim

if has("vms")
  set nobackup		" do not keep a backup file, use versions instead
else
  set backup		" keep a backup file (restore to previous version)
  if has('persistent_undo')
    set undofile	" keep an undo file (undo changes after closing)
  endif
endif

" Start NERDTree. If a file is specified, move the cursor to its window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif

" Auto-format Python files using Black
autocmd BufWritePre *.py Black

colorscheme pablo

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

if has("gui_running")
  colorscheme anderson
endif
