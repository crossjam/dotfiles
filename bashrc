if [[ "$INSIDE_EMACS" == *comint* || "$INSIDE_EMACS" == *vterm* ]]; then
  export TERM=xterm-256color
  set -o emacs
fi

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

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

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"  # Apple Silicon

[[ -r ~/.config/op/plugins.sh ]] && . ~/.config/op/plugins.sh

alias claude="$HOME/.claude/local/claude"

# Assume most environments will only have one of the following
[ -f /opt/homebrew/etc/profile.d/bash-preexec.sh ] && . /opt/homebrew/etc/profile.d/bash-preexec.sh
[ -f /usr/local/etc/profile.d/bash-preexec.sh ] && . /usr/local/etc/profile.d/bash-preexec.sh

# [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh

eval "$(starship init bash)"
eval "$(zoxide init bash)"
eval "$(atuin init bash)"
eval "$(direnv hook bash)"