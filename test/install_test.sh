#!/bin/bash

docker run --rm -it \
       --mount "type=bind,source=$PWD/install_dotfiles.sh,target=/home/crossjam/install_dotfiles.sh" \
       --mount "type=bind,source=$HOME/.ssh/crossjam.ecdsa,target=/home/crossjam/.ssh/id_ecdsa" \
       dotfiles-test
