alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ew="emacsclient -c -n"
alias et="emacsclient -t"

aimux() {
    TERM=xterm-256color tmux new-session -A -s "${1:-main}"
}
