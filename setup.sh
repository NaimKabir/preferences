#!/bin/bash

set -euo pipefail

# Pass a fully qualified path to this repo as an arg
# to make the correct symlinks
REPO_PATH="$1"

TARGET_TMUX_CONF=~/.tmux.conf
TARGET_VIM_FOLDER=~/.vim
TARGET_VIMRC=~/.vimrc
TARGET_AEROSPACE=~/.aerospace.toml

# Cleanup
rm -f $TARGET_TMUX_CONF
rm -rf $TARGET_VIM_FOLDER
rm -f $TARGET_VIMRC
rm -f $TARGET_AEROSPACE

# Creating dirs

mkdir -p ~/vimtmp # creating a place for vim to store backups/swaps/undos

# Symlinks

ln -s $REPO_PATH/tmux.conf $TARGET_TMUX_CONF
ln -s $REPO_PATH/vimrc $TARGET_VIMRC
ln -s $REPO_PATH/vim $TARGET_VIM_FOLDER 
ln -s $REPO_PATH/aerospace.toml $TARGET_VIM_FOLDER 

# Clone git submodules to get plugin source
git submodule update --init --recursive
