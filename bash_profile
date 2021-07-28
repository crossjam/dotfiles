if [[ -x /opt/homebrew/bin/brew ]]; then
   eval $(/opt/homebrew/bin/brew shellenv)
elif [[ -x /usr/local/bin/brew ]]; then
   eval $(/usr/local/bin/brew shellenv)
else
   echo "Couldn't find brew command";
fi

if [[ -n $(type -p pyenv) ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
elif [[ $OSTYPE == "linux-"* && -d "$HOME/.pyenv" ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
fi

# Created by `userpath` on 2020-06-27 23:35:17
export PATH="$PATH:$HOME/.local/bin"
export PATH=$PATH:/usr/local/bin:/usr/local/sbin

if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
	source "$HOME/.bashrc"
    fi
fi
