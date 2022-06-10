#!/bin/bash
git clone https://github.com/Homebrew/brew $HOME/.linuxbrew
eval "$($HOME/.linuxbrew/bin/brew shellenv)"
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
