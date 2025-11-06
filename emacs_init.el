(when (eq system-type 'darwin)
  (defun my/brew-prefix ()
    (require 'subr-x)

    "Return Homebrew prefix, or best-guess if brew isn't on PATH yet.
     Resolves correctly for Intel (/usr/local) and Apple Silicon (/opt/homebrew).
     If Emacs is running under Rosetta (x86_64 on Apple Silicon), prefers /usr/local."

    (let* ((emacs-arch   (cond
			  ((string-match-p "aarch64" system-configuration) 'arm64)
                          ((string-match-p "x86_64"  system-configuration) 'x86_64)
                          (t nil)))
	   (guess        (pcase emacs-arch
			   ('arm64  "/opt/homebrew")
			   ('x86_64 "/usr/local")
			   (_       "/usr/local")))  ; safe default
	   (brew-exe     (or (executable-find "brew")
                             ;; Try common locations before PATH is fixed:
			     (car (seq-filter #'file-executable-p
					      '("/opt/homebrew/bin/brew"
                                                "/usr/local/bin/brew"))))))
      (if brew-exe
	  (let* ((out  (with-temp-buffer
			 (call-process brew-exe nil t nil "--prefix")
			 (string-trim (buffer-string)))))
	    (if (and out (file-directory-p out)) out guess))
	guess)))
  )

(my/brew-prefix)

(let* ((prefix (my/brew-prefix))
       (bin    (expand-file-name "bin"  prefix))
       (bash   (expand-file-name "bash" bin)))

  (setenv "SHELL" bash)
  (setq brew-bash bash)
  )

(setq-default custom-file
	      (expand-file-name ".custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))


(require 'package)
(require 'tramp)
(require 'tramp-sh)

(setq-default
 load-prefer-newer t
 package-enable-at-startup nil)


(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ;; Uncomment if you truly need the more curated but slower-to-update builds
        ;; ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("melpa"  . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu"    . 5)
        ("nongnu" . 4)
        ("melpa"  . 3)
        ("melpa-stable" . 2)))

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


(use-package org
  :defer t
  :hook (auto-save . org-save-all-org-buffers)
  :ensure t)

(use-package org-contrib
  :after org
  :ensure t
  :config
  (require 'ox-extra)
  (ox-extras-activate '(ignore-headlines)))

(use-package magit)
(use-package json)
(use-package vterm
  :custom
  (vterm-shell brew-bash))

(use-package rg :ensure t)
(use-package wgrep-ag :ensure t)

(use-package yaml-mode)
(use-package go-mode)
(use-package json-mode)
(use-package jq-mode)
(use-package markdown-mode
  :ensure t
  :mode
  ("\\.Rmd\\'" . poly-markdown-mode)
  ("\\.md\\'" . poly-markdown-mode)
  ("\\.qmd\\'" . poly-markdown-mode))
(use-package polymode :ensure t)

;; (use-package poly-markdown
;;   :ensure t
;;   :mode
;;   ("\\.Rmd\\'" . poly-markdown-mode)
;;   ("\\.md\\'" . poly-markdown-mode)
;;   ("\\.qmd\\'" . poly-markdown-mode))

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


