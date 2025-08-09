if [[ -x /opt/homebrew/bin/brew ]]; then
   eval $(/opt/homebrew/bin/brew shellenv)
elif [[ -x /usr/local/bin/brew ]]; then
   eval $(/usr/local/bin/brew shellenv)
else
   echo "Warning: brew command is not available";
fi

export PYTHONUSERBASE=$HOME/.local

export EDITOR="emacsclient -t"
export VISUAL="emacsclient -c"
export ALTERNATE_EDITOR=""

export PATH=$PATH:$HOME/.local/bin:$HOME/.cargo/bin
export PATH=$PATH:/usr/local/bin:/usr/local/sbin


if [[ -x $HOME/.local/bin/neowofetch ]]; then
   neowofetch --package_managers off --pacakge_minimal
elif command -v brew >/dev/null 2>&1 && brew --prefix hyfetch >/dev/null 2>&1; then
   $(brew --prefix hyfetch)/bin/neowofetch --package_managers off --package_minimal
fi

# Following advice from Glyph Lefkowitz on just using the PSF Python on macos
#
# https://blog.glyph.im/2023/08/get-your-mac-python-from-python-dot-org.html
#

if [[ $OSTYPE == "darwin"* ]]; then
   PATH="/Library/Frameworks/Python.framework/Versions/3.13/bin:${PATH}"
   PATH="/Library/Frameworks/Python.framework/Versions/3.12/bin:${PATH}"
   PATH="/Library/Frameworks/Python.framework/Versions/3.11/bin:${PATH}"
   
   if command -v brew >/dev/null 2>&1 && command -v rustup >/dev/null 2>&1; then
      rustup_path="$(brew --prefix rustup)/bin"
      cargo_path=$(rustup which cargo)
      echo "rustup tools are located at: $rustup_path"
      echo "cargo is located at: $cargo_path"
      PATH="$PATH:$rustup_path"
    else  
      echo "rustup is not installed or not in PATH"
    fi

   if command -v brew >/dev/null 2>&1 && brew --prefix libpq >/dev/null 2>&1; then
      libpq_path="$(brew --prefix libpq)/bin"
      echo "libpq tools are located at: $libpq_path"
      PATH="$PATH:$libpq_path"
    else  
      echo "libpq is not installed or not in PATH"
    fi

    if [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]]; then
       export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    fi

    if [[ -x "/Applications/Postgres.app/Contents/Versions/latest/bin/" ]]; then
       export PATH="$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin/"
    fi
fi

if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
	source "$HOME/.bashrc"
    fi
fi

export PATH
