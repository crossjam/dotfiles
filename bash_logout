if [[ "$(uname)" != "Darwin" ]]; then
  # Your logout logic here, e.g.:
  if ! screen -list 2>/dev/null | grep -q '\.screen'; then
    emacsclient --eval '(kill-emacs)' >/dev/null 2>&1
  fi
fi