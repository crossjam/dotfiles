#!/bin/bash
export NONINTERACTIVE=t
export DEBIAN_FRONTEND=noninteractive
# export GIT_HTTP_MAX_REQUEST_BUFFER=100M
# export GIT_CORE_COMPRESSION=0

export PYTHONUSERBASE=$HOME/.local

# On macOS, it's best to install the python.org version of python
if [[ $OSTYPE == "darwin"* ]]; then
    PIP_REQUIRE_VIRTUALENV=false /Library/Frameworks/Python.framework/Versions/Current/bin/python3 -m pip install --user pipx
  else
    PIP_REQUIRE_VIRTUALENV=false python3 -m pip install --user pipx
fi    

PATH=$PATH:$HOME/.local/bin
# pipx install homely
# pipx install git+ssh://git@github.com/crossjam/homely.git

if ! pipx list | grep -q "package uv"; then
    pipx install uv
fi

# Personal fork with fixes for asyncio deprecations
if ! uv tool list | grep -q homely; then
    uv tool install "homely @ git+https://github.com/crossjam/homely"
fi

homely add dotfiles
unset GIT_SSH_COMMAND

