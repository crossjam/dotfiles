if [[ "$(uname)" != "Darwin" ]]; then
  # Your logout logic here, e.g.:
  if ! screen -list | grep -q '\.screen'; then
    emacsclient --eval '(kill-emacs)' >/dev/null 2>&1
  fi
fi