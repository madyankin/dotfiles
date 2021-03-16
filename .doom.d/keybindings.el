;;; keybindings.el ---

(if (eq system-type 'darwin)
  (define-key global-map (kbd "S-c") 'kill-ring-save)
  (define-key global-map (kbd "S-v") 'yank)
  (define-key global-map (kbd "S-x") 'kill-region)
)

(use-package reverse-im
  :ensure t
  :custom
  (reverse-im-input-methods '("russian-computer"))
  :config
  (reverse-im-mode t))
