#!/bin/bash
export NONINTERACTIVE=t

git config --global core.compression 0
git config --global http.postBuffer 1048576000

pip install --user homely
PATH=$PATH:$HOME/.local/bin
git clone git@github.com:crossjam/dotfiles.git
cd dotfiles
git checkout ${DOTFILES_BRANCH:-master}
cd ..
homely add dotfiles
homely update
