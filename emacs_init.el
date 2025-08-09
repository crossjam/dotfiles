(setenv "SHELL" "/opt/homebrew/bin/bash")

(setq-default custom-file
	      (expand-file-name ".custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

(setq vterm-shell "/opt/homebrew/bin/bash")

(require 'package)
(require 'tramp)
(require 'tramp-sh)

(setq-default
 load-prefer-newer t
 package-enable-at-startup nil)

(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)

(package-initialize)

 ;; Install dependencies
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package t))
(setq-default
 use-package-always-defer t
 use-package-always-ensure t)

(use-package unicode-fonts
  :ensure t
  :config
  (unicode-fonts-setup))


(setq exec-path-from-shell-variables '())

(dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG" "LC_CTYPE" "PYTHONUSERBASE" "PATH" "SHELL"))
  (add-to-list 'exec-path-from-shell-variables var))

;; sync PATH from env especially on OS X
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :ensure t
  :config (exec-path-from-shell-initialize))


(use-package org :ensure org-plus-contrib)
(use-package magit)
(use-package json)
(use-package vterm
  :custom
  (vterm-shell "/opt/homebrew/bin/bash"))

(use-package rg :ensure t)
(use-package wgrep-ag :ensure t)

(use-package yaml-mode)
(use-package go-mode)
(use-package json-mode)
(use-package jq-mode)
(use-package markdown-mode)
(use-package blacken)

(use-package ansi-color)
(use-package mellow-theme)
(use-package material-theme)
(use-package ample-theme)
(use-package solarized-theme)
(use-package cycle-themes)

(use-package yasnippet
  :config
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  (yas-global-mode 1))

(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

;;; the next batch of prompt hacking was written by claude
(defun starship-prompt-extract-and-clean-last-line (output)
  "Extract last line, strip ANSI codes for directory tracking, but preserve original output."
  (let* ((lines (split-string output "\n"))
         (last-line (car (last lines)))
         ;; Work on a COPY for directory extraction
         (clean-line (ansi-color-filter-apply (copy-sequence last-line))))

    (message "Looking for prompt in: %s" clean-line)
    
    (when (string-match "\\([~/][/a-zA-Z0-9._-]*\\|/[/a-zA-Z0-9._-]*\\)[[:space:]]*.*[[:space:]]❯" clean-line)
      (let ((dir (match-string 1 clean-line)))
        (condition-case err
            (progn
              (setq default-directory (file-name-as-directory (expand-file-name dir)))
              (when dirtrack-debug
                (message "Dirtrack: changed to directory '%s'" default-directory)))
          (error 
           (when dirtrack-debug
             (message "Dirtrack: failed to change to directory '%s': %s" dir err))))))
    
    ;; Return the ORIGINAL output unchanged for display
    output))

(defun starship-setup-shell-dirtrack ()
  "Setup custom directory tracking while preserving ANSI display."
  (interactive)
  
  ;; Disable default modes
  (shell-dirtrack-mode -1)
  (when (fboundp 'dirtrack-mode) (dirtrack-mode -1))
  
  ;; Make sure ansi-color processes output for display
  (add-hook 'comint-output-filter-functions 'ansi-color-process-output nil 'local)
  
  ;; Add our directory tracking filter AFTER ansi-color processing
  (add-hook 'comint-output-filter-functions 
            'starship-prompt-extract-and-clean-last-line nil 'local)
  
  (setq dirtrack-debug t))

(add-hook 'shell-mode-hook 'starship-setup-shell-dirtrack)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(add-hook 'python-mode-hook
 	  (lambda (&optional val) (turn-on-eldoc-mode)))
(add-hook 'python-mode-hook 'blacken-mode)

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda () (flyspell-mode 1))))

;; (add-hook 'auto-save-hook 'org-save-all-org-buffers)

(add-hook 'markdown-mode-hook 'electric-quote-mode)
(add-hook 'markdown-mode-hook 'auto-fill-mode)

(with-eval-after-load 'tramp
  (setq tramp-ssh-controlmaster-options
        (concat tramp-ssh-controlmaster-options " -o ForwardAgent=yes"))
  )

(setq magit-commit-ask-to-stage 'verbose)

;;; Bind the path so that we don't pickup virtualenv binaries that may be set
(let ((exec-path '("~/.local/bin", "/opt/homebrew/bin", "/usr/local/bin")))
  (setq blacken-executable (executable-find "black")))

;;; Bind the path so that we don't pickup virtualenv binaries that may be set

(let ((exec-path
       '("/opt/homebrew/bin",
	 "/usr/local/bin",
	 (expand-file-name "~/.local/bin"))))
  (setq blacken-executable (executable-find "black")))

(setq python-shell-completion-native-enable nil)

(quail-define-package
 "Emoji" "UTF-8" "😎" t
 "Emoji input mode for people that really, really like Emoji"
 '(("\t" . quail-completion))
 t t nil nil nil nil nil nil nil t)

(quail-define-rules
 (":)" ?😀)
 (":P" ?😋)
 (":D" ?😂)
 (":thumb:" ?👍))

(global-set-key (kbd "C-c g") 'goto-line)
(global-set-key (kbd "C-c m") 'manual-entry)
(global-set-key (kbd "C-c s") 'magit-status)

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(global-set-key (kbd "C-c b") 'blacken-buffer)

(with-eval-after-load 'transient
  (transient-bind-q-to-quit))

;; (setq insert-directory-program "gls" dired-use-ls-dired t)

;; (setq exec-path-from-shell-variables '())

(setq
 insert-directory-program (or (executable-find "gls") (executable-find "ls"))
 dired-use-ls-dired t)

(setq dired-listing-switches "-aBhlt  --group-directories-first")

(load-theme 'material t)
(shell)

(switch-to-buffer "*shell*")

(if (and (fboundp 'server-running-p) 
         (not (server-running-p)))
    (server-start))


