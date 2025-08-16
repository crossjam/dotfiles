# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

if [[ "$INSIDE_EMACS" == *vterm* ]]; then
  export TERM=xterm-256color
  set -o emacs

  vterm_printf() {
    if [ -n "$TMUX" ] \
        && { [ "${TERM%%-*}" = "tmux" ] \
            || [ "${TERM%%-*}" = "screen" ]; }; then
        # Tell tmux to pass the escape sequences through
        printf "\ePtmux;\e\e]%s\007\e\\" "$1"
    elif [ "${TERM%%-*}" = "screen" ]; then
        # GNU screen (screen, screen-256color, screen-256color-bce)
        printf "\eP\e]%s\007\e\\" "$1"
    else
        printf "\e]%s\e\\" "$1"
    fi
  }
  
  vterm_cmd() {
    local vterm_elisp
    vterm_elisp=""
    while [ $# -gt 0 ]; do
        vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
        shift
    done
    vterm_printf "51;E$vterm_elisp"
  }
elif [[ "$INSIDE_EMACS" == *comint* ]]; then
  export TERM=xterm-256color
  set -o emacs
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

if [[ -n $(type -p gdircolors) ]]; then
   if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
       eval "$(TERM=xterm-256color gdircolors -b ~/.dircolors.emacs)"
       PS1='${debian_chroot:+($debian_chroot)}\[\033[01;38;5;117m\]\u@\h\[\033[00m\]:\[\033[01;38;5;117m\]\w\[\033[00m\]\$ '
    else
        test -r ~/.dircolors && eval "$(TERM=xterm-256color gdircolors -b ~/.dircolors.emacs)" || eval "$(gdircolors -b)"
    fi

    alias ls='gls -f -CF --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
elif [[ -n $(type -p dircolors) ]]; then
   if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
       eval "$(TERM=xterm-256color dircolors -b ~/.dircolors.emacs)"
    else
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
    alias ls='ls -f -CF --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

if [ -r ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"  # Apple Silicon

[[ -r "~/.config/op/plugins.sh" ]] && . ~/.config/op/plugins.sh

uvp() {
    local project_name
    local dir_name=$(basename "$PWD")
    
    # If there are no arguments or the last argument starts with a dash, use dir_name
    if [ $# -eq 0 ] || [[ "${!#}" == -* ]]; then
        project_name="$dir_name"
    else
        project_name="${!#}"
        set -- "${@:1:$#-1}"
    fi
    
    UV_PROJECT_ENVIRONMENT="$PWD/.${project_name:-venv}"

    # Check if .envrc already exists
    if [ -f .envrc ]; then
        echo "Error: .envrc already exists" >&2
        return 1
    fi


    # Create .envrc
    echo "export UV_PROJECT_ENVIRONMENT=${UV_PROJECT_ENVIRONMENT}" >> .envrc
    echo "layout python" >> .envrc

    # Create Python package using uv with all passed arguments
    if ! uv init --package --build-backend setuptools --name $project_name; then
        echo "Error: Failed to create uv project" >&2
        return 1
    fi

    # Create Python package using uv with all passed arguments
    if ! uv sync; then
        echo "Error: Failed to sync uv project" >&2
        return 1
    fi

    # Append to ~/.projects
    echo "${project_name}=${PWD}" >> ~/.projects

    # Allow direnv to immediately activate the virtual environment
    direnv allow
}

uvpi() {
    local project_name=$(basename "$PWD")

    if [ -n "$UV_PROJECT_ENVIRONMENT" ]; then
    	 :
    elif [ -n "$VIRTUAL_ENV" ]; then
       	 UV_PROJECT_ENVIRONMENT="$VIRTUAL_ENV"
    elif [ -d ".venv" ]; then
     	 UV_PROJECT_ENVIRONMENT="$PWD/.venv"
    else
	 UV_PROJECT_ENVIRONMENT="$PWD/$project_name"
    fi

    echo "UV_PROJECT_ENVIRONMENT=$UV_PROJECT_ENVIRONMENT"

    # Check if .envrc already exists
    if [ -f .envrc ]; then
        echo "Error: .envrc already exists" >&2
        return 1
    fi

    # Create .envrc
    echo "export UV_PROJECT_ENVIRONMENT=${UV_PROJECT_ENVIRONMENT}" >> .envrc
    echo "layout python" >> .envrc

    # Allow direnv to immediately activate the virtual environment
    direnv allow
}


# Assume the platforms I work on will only have one of the following
[ -f /opt/homebrew/etc/profile.d/bash-preexec.sh ] && . /opt/homebrew/etc/profile.d/bash-preexec.sh
[ -f /usr/local/etc/profile.d/bash-preexec.sh ] && . /usr/local/etc/profile.d/bash-preexec.sh
[ -f ~/.bash-preexec.sh ] && . ~/.bash-preexec.sh

if [ -f $HOME/.atuin/bin/env ]; then
    . "$HOME/.atuin/bin/env"
fi

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --bash)"
eval "$(zoxide init bash)"
eval "$(direnv hook bash)"
eval "$(atuin init bash)"
eval "$(starship init bash)"

if [[ "$INSIDE_EMACS" == *vterm* ]]; then
   vterm_prompt_end(){
	 vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
   }

   vff() {
    vterm_cmd find-file "$(realpath "${@:-.}")"
   }

   starship_precmd_user_func="vterm_prompt_end"
fi

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/crossjam/.lmstudio/bin"
# End of LM Studio CLI section

