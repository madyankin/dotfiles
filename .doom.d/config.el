;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq
 user-full-name "Alexander Madyankin"
 user-mail-address "alexander@madyankin.name"

 doom-font (font-spec :family "JetBrains Mono" :size 14)
 doom-theme 'doom-dracula

 display-line-numbers-type nil

 org-bullets-bullet-list '("·")
 org-support-shift-select t
 org-catch-invisible-edits 'smart
 org-directory "~/Dropbox/Org/"
 org-link-file-path-type 'relative
 org-agenda-files (directory-files-recursively "~/Dropbox/Org/" "\\.org$")
 org-todo-keywords '((sequence "TODO(t)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELED(c@)"))

 my-zettelkasten-directory (concat org-directory "zettelkasten")
 my-journal-directory (concat org-directory "journal")
 my-org-templates-directory (concat org-directory "utils/templates/")
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


(defun my/calendar-week-number ()
  (car
   (calendar-iso-from-absolute
   (calendar-absolute-from-gregorian
    (calendar-current-date)))))

(defun my/year-progress ()
  (concat
   "Текущая неделя:\n"
   (number-to-string (my/calendar-week-number))
   "/52 ["
   (make-string (my/calendar-week-number) ?=)
   (make-string (- 52 (my/calendar-week-number)) ? )
   "] "
   (number-to-string (fround (/ (* 100 (my/calendar-week-number)) 52.0)))
   "% года прошло"))


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
           "** %(format-time-string org-journal-time-format)\n%i%?" :empty-lines 1)

          ("w" "Week summary" item
           (file+olp+datetree "~/Org/utils/templates/week-summary.org"
                              "* %?"
                              :tree-type week))

          ("n" "New note" plain
           (file my/new-note-path)
           "#+TITLE: %i%? \n#+ROAM_ALIAS: \"\" \n#+ROAM_TAGS: \n\n* References: \n"))))


(setq my/new-note-timestamp-format "%Y-%m-%dT%H%M%S")

(defun my/new-note-path ()
  (concat my-zettelkasten-directory
          "/"
          (format-time-string my/new-note-timestamp-format)
          ".org"))

(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)

  :init
  (setq org-roam-directory my-zettelkasten-directory
        org-roam-graph-viewer "/usr/bin/open")
  (map! :leader
        :prefix "n"
        :desc "org-roam" "l" #'org-roam
        :desc "org-roam-insert" "i" #'org-roam-insert
        :desc "org-roam-switch-to-buffer" "b" #'org-roam-switch-to-buffer
        :desc "org-roam-find-file" "f" #'org-roam-find-file
        :desc "org-roam-graph" "g" #'org-roam-graph
        :desc "org-roam-insert" "i" #'org-roam-insert
        :desc "org-roam-capture" "c" #'org-roam-capture)

  :config
  (setq org-roam-capture-templates
        '(("d" "default" plain (function org-roam--capture-get-point)
           "%? \n\n* References\n\n"
           :file-name "%(format-time-string my/new-note-timestamp-format)"
           :head "#+TITLE: ${title} \n#+ROAM_ALIAS: \"\" \n#+ROAM_TAGS: \n\n"
           :unnarrowed t)))
  (org-roam-mode +1))

(use-package! ob-C :after org)
(use-package! ob-emacs-lisp :after org)
(use-package! ob-java :after org)
(use-package! ob-js :after org)
(use-package! ob-makefile :after org)
(use-package! ob-org :after org)
(use-package! ob-python :after org)
(use-package! ob-ruby :after org)
(use-package! ob-shell :after org)

(use-package! deft
  :after org
  :bind ("C-M-S-s-d" . deft)
  :custom
  (deft-new-file-format my/new-note-timestamp-format)
  (deft-recursive t)
  (deft-default-extension "org")
  (deft-directory org-directory))


(use-package! org-journal
  :after org
  :init
  (map! :leader
        :prefix "j"
        :desc "Today journal file" "o" #'org-journal-open-current-journal-file
        :desc "New journal entry" "j" #'(lambda () (interactive) (org-capture 1 "j"))
        :desc "New journal todo" "t" #'(lambda () (interactive) (org-capture 1 "t")))
  :custom
  (org-journal-file-type 'monthly)
  (org-journal-file-format "%Y-%m.org")
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


(use-package ox-hugo
  :after ox)


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
;;
;;
(load! "appearance")
(load! "keybindings")
(load! "../.config/emacs.private.el")

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("99ea831ca79a916f1bd789de366b639d09811501e8c092c85b2cb7d697777f93" "dde8c620311ea241c0b490af8e6f570fdd3b941d7bc209e55cd87884eb733b0e" "93ed23c504b202cf96ee591138b0012c295338f38046a1f3c14522d4a64d7308" "9b01a258b57067426cc3c8155330b0381ae0d8dd41d5345b5eddac69f40d409b" "7a994c16aa550678846e82edc8c9d6a7d39cc6564baaaacc305a3fdc0bd8725f" "0cb1b0ea66b145ad9b9e34c850ea8e842c4c4c83abe04e37455a1ef4cc5b8791" "c342ef444e7aca36f4b39a8e2848c4ba793d51c58fdb520b8ed887766ed6d40b" default))
 '(package-selected-packages '(reverse-im ox-hugo)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
