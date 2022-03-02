#!/bin/bash
export NONINTERACTIVE=t

git config --global core.compression 0
git config --global http.postBuffer 1048576000

pip install --user homely
PATH=$PATH:$HOME/.local/bin
cd dotfiles
git checkout ${DOTFILES_BRANCH:-main}
cd ..
homely add dotfiles
