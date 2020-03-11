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

(use-package org :ensure org-plus-contrib)
(use-package magit)
(use-package json)

(use-package yaml-mode)
(use-package go-mode)
(use-package json-mode)
(use-package jq-mode)
(use-package blacken)

(use-package ansi-color)
(use-package mellow-theme)
(use-package material-theme)
(use-package ample-theme)
(use-package solarized-theme)
(use-package cycle-themes)


(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'python-mode-hook
 	  (lambda (&optional val) (turn-on-eldoc-mode)))
(add-hook 'python-mode-hook 'blacken-mode)
(add-hook 'auto-save-hook 'org-save-all-org-buffers)

(setq blacken-executable "/usr/local/bin/black")

(when (file-accessible-directory-p "~/Dropbox/Data Machines Corporation/Project Management/")
  (setq org-agenda-files
	'("~/Dropbox/Data Machines Corporation/Project Management/")))

(setq python-shell-completion-native-enable nil)

(global-set-key (kbd "C-c g") 'goto-line)
(global-set-key (kbd "C-c m") 'manual-entry)
(global-set-key (kbd "C-c s") 'magit-status)

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(with-eval-after-load 'transient
  (transient-bind-q-to-quit))

(load-theme 'material t)
(shell)

(switch-to-buffer "*shell*")

