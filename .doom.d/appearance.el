(add-hook 'ns-system-appearance-change-functions
          #'(lambda (appearance)
              (mapc #'disable-theme custom-enabled-themes)
              (pcase appearance
                ('light (load-theme 'doom-one-light t))
                ('dark (load-theme 'doom-dracula t)))))
