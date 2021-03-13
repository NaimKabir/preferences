" Enable syntax highlighting
syntax enable

" Swap out window navigation commands with Mac friendly ones.
" Swapping ctrl-W prepends for window down/up/left/right with
" raw ctrl-J, ctrl-K, etc. 
nnoremap <C-J> <C-W>j
nnoremap <C-K> <C-W>k
nnoremap <C-L> <C-W>l
nnoremap <C-H> <C-W>h
" Swapping out window close command
nnoremap <C-C> <C-W>c
" Swapping out split screen horizontal
nnoremap <C-V> <C-W>v
" Swapping out split screen vertical
nnoremap <C-S> <C-W>s

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

if &t_Co > 2 || has("gui_running")
  " Switch on highlighting the last used search pattern.
  set hlsearch
endif

colorscheme koehler
