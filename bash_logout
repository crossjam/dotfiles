if [[ "$(uname)" != "Darwin" ]]; then
  if ! screen -list 2>/dev/null | grep -q '\.screen'; then
    if emacsclient --alternate-editor=none -e '(emacs-pid)' >/dev/null 2>&1; then
      emacsclient --eval '(kill-emacs)' >/dev/null 2>&1
    fi
  fi
fi
