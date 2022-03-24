(setq-default custom-file
	      (expand-file-name ".custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(require 'package)

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

(use-package exec-path-from-shell) ;; sync PATH from env especially on OS X
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :ensure t
  :config
  (exec-path-from-shell-initialize))

(use-package org :ensure org-plus-contrib)
(use-package magit)
(use-package json)

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

(use-package org-gcal)

;; (when (memq window-system '(mac ns x))
;;   (exec-path-from-shell-initialize))

(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'python-mode-hook
 	  (lambda (&optional val) (turn-on-eldoc-mode)))
(add-hook 'python-mode-hook 'blacken-mode)
(add-hook 'auto-save-hook 'org-save-all-org-buffers)

(add-hook 'markdown-mode-hook 'electric-quote-mode)
(add-hook 'markdown-mode-hook 'auto-fill-mode)

;;; Bind the path so that we don't pickup virtualenv binaries that may be set
(let ((exec-path '("/opt/homebrew/bin", "/usr/local/bin")))
  (setq blacken-executable (executable-find "black")))

(setq python-shell-completion-native-enable nil)

(global-set-key (kbd "C-c g") 'goto-line)
(global-set-key (kbd "C-c m") 'manual-entry)
(global-set-key (kbd "C-c s") 'magit-status)

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(with-eval-after-load 'transient
  (transient-bind-q-to-quit))

;; (setq org-agenda-time-grid
;;       '((daily today)
;; 	(800 1000 1200 1400 1600 1800 2000)
;; 	"......" "----------------"))

;; (when (or (string= (user-login-name) "bmdmc")
;; 	  (string= (user-login-name) "brian.dennis"))
;;   (setq org-gcal-remove-api-cancelled-events t
;; 	org-gcal-up-days 14
;; 	org-gcal-down-days 30
;; 	org-gcal-client-id
;; 	"783058594145-hkk7p3nmgb1e416vmndi2j2448mlitot.apps.googleusercontent.com"
;; 	org-gcal-client-secret "nlDtFi7e8ZkZg0xPVE_UBNzV"
;; 	org-gcal-file-alist
;; 	'(("briandennis@datamachines.io" . "~/Dropbox/Data Machines Corporation/Project Management/gcal.org"))
;; 	))


(load-theme 'material t)
(shell)

(switch-to-buffer "*shell*")

