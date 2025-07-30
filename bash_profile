if [[ -x $HOME/.linuxbrew/bin/brew ]]; then
   eval $($HOME/.linuxbrew/bin/brew shellenv)
elif [[ -x /opt/homebrew/bin/brew ]]; then
   eval $(/opt/homebrew/bin/brew shellenv)
elif [[ -x /usr/local/bin/brew ]]; then
   eval $(/usr/local/bin/brew shellenv)
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
   eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else
   echo "Warning: brew command is not available";
fi

# Following advice from Glyph Lefkowitz on just using the PSF Python on macos
#
# https://blog.glyph.im/2023/08/get-your-mac-python-from-python-dot-org.html
#
# Setting PATH for Python 3.11
# Could conceivably use Current in place of 3.11
#

if [[ $OSTYPE == "darwin"* ]]; then
    PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
fi

# Created by `userpath` on 2020-06-27 23:35:17
export PATH="$PATH:$HOME/.local/bin:$HOME/.cargo/bin"
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
export EDITOR="emacs -nw"
export PYTHONUSERBASE=$HOME/.local

if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]]; then
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

if [[ -x "/Applications/Postgres.app/Contents/Versions/latest/bin/" ]]; then
   export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin/"
fi

if [[ -x "/opt/homebrew/opt/libpq/bin" ]]; then
   export PATH="$PATH:/opt/homebrew/opt/libpq/bin"
fi

if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
	source "$HOME/.bashrc"
    fi
fi

export PATH

# Setting PATH for Python 3.12
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:${PATH}"
export PATH

# Setting PATH for Python 3.13
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:${PATH}"
export PATH

# Setting PATH for Python 3.13
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:${PATH}"
export PATH
