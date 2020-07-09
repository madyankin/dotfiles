;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq
 user-full-name "Alexander Madyankin"
 user-mail-address "alexander@madyankin.name"

 doom-font (font-spec :family "JetBrains Mono" :size 14)
 doom-theme 'doom-dracula

 display-line-numbers-type t

 org-bullets-bullet-list '("·")
 org-support-shift-select t
 org-catch-invisible-edits 'smart
 org-directory "~/Org/"

 my-zettelkasten-directory (concat org-directory "zettelkasten")
 my-journal-directory (concat org-directory "journal")
)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.

(add-hook 'ns-system-appearance-change-functions
          #'(lambda (appearance)
              (mapc #'disable-theme custom-enabled-themes)
              (pcase appearance
                ('light (load-theme 'doom-one-light t))
                ('dark (load-theme 'doom-dracula t)))))


;; Org related stuff

(global-set-key (kbd "s-=") 'org-capture)

(after! org
  (map! :map org-mode-map
        :n "M-j" #'org-metadown
        :n "M-k" #'org-metaup
        :ne "C-s-<down>" #'org-narrow-to-subtree
        :ne "C-s-<up>" #'widen)

  (setq
   org-image-actual-width 400
   org-capture-templates
        '(("t" "TODO in Journal" entry
           (function org-journal-find-location)
           "** TODO %i%?" :empty-lines 1)

          ("j" "Journal" entry
           (function org-journal-find-location)
           "** %(format-time-string org-journal-time-format)\n%i%?" :empty-lines 1))))


(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)
  :init
  (setq org-roam-directory my-zettelkasten-directory)
  (setq org-roam-graph-viewer "/usr/bin/open")
  (map! :leader
        :prefix "n"
        :desc "Org-Roam-Insert" "i" #'org-roam-insert
        :desc "Org-Roam-Find" "/" #'org-roam-find-file
        :desc "Org-Roam-Buffer" "b" #'org-roam)
  :config
  (org-roam-mode +1))


(use-package! deft
  :after org
  :bind ("C-M-S-s-d" . deft)
  :custom
  (deft-new-file-format "%Y-%m-%dT%H%M")
  (deft-recursive t)
  (deft-default-extension "org")
  (deft-directory my-zettelkasten-directory))


(use-package! org-journal
  :after org
  :init
  (map! :leader
        :prefix "j"
        :desc "Today journal file" "o" #'org-journal-open-current-journal-file
        :desc "New journal entry" "j" #'(lambda () (interactive) (org-capture 1 "j"))
        :desc "New journal todo" "t" #'(lambda () (interactive) (org-capture 1 "t")))
  :custom
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-date-format "%A, %d %B %Y")
  (org-journal-dir my-journal-directory))

;; Org journal fn for capture
(defun org-journal-find-location ()
  (org-journal-new-entry t) (goto-char (point-min)))


;; Drawing diagrams with Graphviz in org-mode
(org-babel-do-load-languages
 'org-babel-load-languages
 '((dot . t)))


(use-package! org-download
  :after org
  :config
  (setq-default org-download-image-dir "./attachments/")
  (setq-default org-download-method 'directory)
  (setq-default org-download-heading-lvl nil)
  (setq org-download-annotate-function (lambda (_link) ""))
  (setq-default org-download-timestamp "%Y-%m-%d_%H-%M-%S_"))



(setq default-input-method "russian-computer")


;; =============
;; MODIFIER KEYS


;; Both command keys are 'Super'
(setq mac-right-command-modifier 'super)
(setq mac-command-modifier 'super)


;; Option or Alt is naturally 'Meta'
(setq mac-option-modifier 'meta)


;; Right Alt (option) can be used to enter symbols like em dashes '—' and euros '€' and stuff.
(setq mac-right-option-modifier 'nil)

;; Control is control, and you also need to change Caps Lock to Control in the Keyboard
;; preferences in macOS.


;; =============
;; SANE DEFAULTS


;; Smoother and nicer scrolling
(setq scroll-margin 10
   scroll-step 1
   next-line-add-newlines nil
   scroll-conservatively 10000
   scroll-preserve-screen-position 1)

(setq mouse-wheel-follow-mouse 't)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))


;; Use ESC as universal get me out of here command
(define-key key-translation-map (kbd "ESC") (kbd "C-g"))


;; Warn only when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)


;; =======
;; VISUALS
;; 
;; Enable transparent title bar on macOS
(when (memq window-system '(mac ns))
  (add-to-list 'default-frame-alist '(ns-appearance . light)) ;; {light, dark}
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (setq auto-dark-emacs/dark-theme 'doom-dracula)
  (setq auto-dark-emacs/light-theme 'doom-one-light)
  (setq-default line-spacing 5))


;; ================
;; BASIC NAVIGATION


;; Move around with Cmd+i/j/k/l. This is not for everybody, and it takes away four very well placed
;; key combinations, but if you get used to using these keys instead of arrows, it will be worth it,
;; I promise.
(global-set-key (kbd "s-i") 'previous-line)
(global-set-key (kbd "s-k") 'next-line)
(global-set-key (kbd "s-j") 'left-char)
(global-set-key (kbd "s-l") 'right-char)


;; Kill line with CMD-Backspace. Note that thanks to Simpleclip, killing doesn't rewrite the system clipboard.
;; Kill one word with Alt+Backspace.
;; Kill forward word with Alt-Shift-Backspace.
(global-set-key (kbd "s-<backspace>") 'kill-whole-line)
(global-set-key (kbd "M-S-<backspace>") 'kill-word)


;; Use Cmd for movement and selection.
(global-set-key (kbd "s-<right>") (kbd "C-e"))        ;; End of line
(global-set-key (kbd "S-s-<right>") (kbd "C-S-e"))    ;; Select to end of line
(global-set-key (kbd "s-<left>") (kbd "M-m"))         ;; Beginning of line (first non-whitespace character)
(global-set-key (kbd "S-s-<left>") (kbd "M-S-m"))     ;; Select to beginning of line

(global-set-key (kbd "s-<up>") 'beginning-of-buffer)  ;; First line
(global-set-key (kbd "s-<down>") 'end-of-buffer)      ;; Last line


; Thanks to Bozhidar Batsov
;; http://emacsredux.com/blog/2013/]05/22/smarter-navigation-to-the-beginning-of-a-line/
(defun smarter-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.

Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.

If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(global-set-key (kbd "C-a") 'smarter-move-beginning-of-line)
(global-set-key (kbd "s-<left>") 'smarter-move-beginning-of-line)


;; Multiple cursors. Similar to Sublime or VS Code.
(use-package multiple-cursors
  :config
  (setq mc/always-run-for-all 1)
  (global-set-key (kbd "s-d") 'mc/mark-next-like-this)        ;; Cmd+d select next occurrence of region
  (global-set-key (kbd "s-D") 'mc/mark-all-dwim)              ;; Cmd+Shift+d select all occurrences
  (global-set-key (kbd "M-s-d") 'mc/edit-beginnings-of-lines) ;; Alt+Cmd+d add cursor to each line in region
  (define-key mc/keymap (kbd "<return>") nil))


;; Go to other windows easily with one keystroke Cmd-something.
(global-set-key (kbd "s-1") (kbd "C-x 1"))  ;; Cmd-1 kill other windows (keep 1)
(global-set-key (kbd "s-2") (kbd "C-x 2"))  ;; Cmd-2 split horizontally
(global-set-key (kbd "s-3") (kbd "C-x 3"))  ;; Cmd-3 split vertically
(global-set-key (kbd "s-0") (kbd "C-x 0"))  ;; Cmd-0...
(global-set-key (kbd "s-w") (kbd "C-x 0"))  ;; ...and Cmd-w to close current window
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("c342ef444e7aca36f4b39a8e2848c4ba793d51c58fdb520b8ed887766ed6d40b" default))
 '(deft-default-extension "org" t)
 '(deft-directory "~/Org/zettelkasten" t)
 '(deft-recursive t t)
 '(org-journal-date-format "%A, %d %B %Y")
 '(org-journal-dir "~/Org/journal")
 '(org-journal-file-format "%Y-%m-%d.org"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
