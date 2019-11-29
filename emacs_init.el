(load-library "url-handlers")

(require 'package)

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("d3df47c843c22d8f0177fe3385ae95583dc8811bd6968240f7da42fd9aa51b0b" default)))
 '(package-selected-packages
   (quote
    (yaml-mode go-mode mellow-theme virtualenvwrapper material-theme dash-at-point cycle-themes ample-theme color-theme-solarized json-mode jq-mode json magit org))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(add-hook 'python-mode-hook (lambda () (turn-on-eldoc-mode nil)))
(setq python-shell-completion-native-enable nil)
(global-set-key (kbd "C-c g") 'goto-line)
(global-set-key (kbd "C-c m") 'manual-entry)
(global-set-key (kbd "C-c s") 'magit-status)

(load-theme 'material t)
(shell)

(switch-to-buffer "*shell*")
