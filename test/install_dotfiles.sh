#!/bin/bash

pip install --user homely
PATH=$PATH:$HOME/.local/bin
git clone git@github.com:crossjam/dotfiles.git
homely add dotfiles
homely update
