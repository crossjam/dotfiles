# trap 'emacsclient --eval "(kill-emacs)" >/dev/null 2>&1' EXIT
trap 'if ! screen -list | grep -q "\.screen"; then emacsclient --eval "(kill-emacs)" >/dev/null 2>&1; fi' EXIT