#!/bin/bash
# Presumably if you just do a
# git clone https://github.com/crossjam/dotfiles
# cd dotfiles
# and run this script things should install

export NONINTERACTIVE=t
export DEBIAN_FRONTEND=noninteractive
# export GIT_HTTP_MAX_REQUEST_BUFFER=100M
# export GIT_CORE_COMPRESSION=0

export PYTHONUSERBASE=$HOME/.local

PATH=$PATH:$HOME/.local/bin:$HOME/.cargo/bin

# Bootstrap uv into the account
curl -LsSf https://astral.sh/uv/0.8.4/install.sh | sh

# Bootstrap pipx into the account with uv
if ! uv tool list | grep -q pipx; then
    uv tool install --managed-python pipx
fi

# Bootstrap homely into the account with uv
# Personal fork with fixes for asyncio deprecations
if ! uv tool list | grep -q homely; then
    uv tool install --with requests --managed-python "homely @ git+https://github.com/crossjam/homely"
fi

homely add dotfiles

