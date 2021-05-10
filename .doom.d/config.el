;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
(setq user-full-name "Alexander Madyankin"
      user-mail-address "alexander@madyankin.name")

(setq doom-font (font-spec :family "JetBrains Mono" :size 14)
      doom-theme 'doom-dracula

      display-line-numbers-type nil
      load-prefer-newer t
      company-idle-delay nil)

(add-hook 'ns-system-appearance-change-functions  #'(lambda (appearance)
                                                     (mapc #'disable-theme custom-enabled-themes)
              (pcase appearance
                ('light (load-theme 'doom-one-light t))
                ('dark (load-theme 'doom-dracula t)))))

(add-hook 'window-setup-hook 'toggle-frame-maximized t)

(setq my/home-dir "~"
      my/org-dir (concat my/home-dir "/Documents/Org/")
      my/org-templates-dir (concat my/org-dir "utils/templates/")
      my/journal-dir my/org-dir
      my/zettels-dir (concat my/org-dir "zettelkasten"))

(unless (equal "Battery status not available" (battery))
  (display-battery-mode 1))

(global-auto-revert-mode t)
(pdf-tools-install)

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

(require 'org-drill)

(setq org-drill-scope 'agenda)
(setq org-drill-add-random-noise-to-intervals-p t)

(defun org-drill-entry-empty-p () nil)

;;; org.el -*- lexical-binding: t; -*-

(setq org-latex-create-formula-image-program 'dvisvgm)


(global-set-key (kbd "s-=") 'org-capture)

(require 'org-habit)

(setq org-bullets-bullet-list '("·")
      org-support-shift-select t
      org-catch-invisible-edits 'smart
      org-log-done 'time
      org-log-into-drawer t
      org-agenda-start-with-log-mode t
      org-directory my/org-dir
      org-link-file-path-type 'relative
      org-agenda-files (directory-files-recursively my/org-dir "\\.org$")
      org-todo-keywords '((sequence "TODO(t)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELED(c@)"))
      org-habit-show-habits t
      org-habit-graph-column 60)

(after! org
  (map! :map org-mode-map
        :n "M-j" #'org-metadown
        :n "M-k" #'org-metaup
        :ne "C-s-<down>" #'org-narrow-to-subtree
        :ne "C-s-<up>" #'widen)

  (add-to-list 'org-modules 'org-habit t)

  (setq
   org-image-actual-width 400
   org-capture-templates
        '(("t" "TODO in Journal" entry
           entry (file+datetree "~/Org/journal.org")
           "*** TODO %i%" :empty-lines 1)

          ("j" "Journal"
           entry (file+datetree "~/Org/journal.org")
           "** %i%?\n" :empty-lines 1)

          ("w" "Week summary" entry
           (function buffer-file-name)
           "** %(format-time-string org-journal-date-format)\n%i%?" :empty-lines 1)

          ("n" "New note" plain
           (file my/new-note-path)
           "#+TITLE: %i%? \n#+ROAM_ALIAS: \"\" \n#+ROAM_TAGS: \n\n* References: \n"))))


(setq my/new-note-timestamp-format "%Y-%m-%dT%H%M%S")

(defun my/new-note-path ()
  (concat my/zettels-dir
          "/"
          (format-time-string my/new-note-timestamp-format)
          ".org"))

(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)

  :init
  (setq org-roam-directory my/zettels-dir
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
  (org-journal-file-type 'yearly)
  (org-journal-file-format "journal.org")
  (org-journal-date-format "%A, %d %B %Y")
  (org-journal-dir my/journal-dir))



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


;; https://ag91.github.io/blog/2020/09/04/the-poor-org-user-spaced-repetition/
(defun my/space-repeat-if-tag-spaced (e)
  "Resets the header on the TODO states and increases the date according to a suggested spaced repetition interval."
  (let* ((spaced-rep-map '((0 . "++1d")
                           (1 . "++2d")
                           (2 . "++10d")
                           (3 . "++30d")
                           (4 . "++60d")
                           (5 . "++4m")))
         (spaced-key "spaced")
         (tags (org-get-tags))
         (spaced-todo-p (member spaced-key tags))
         (repetition-n (car (cdr spaced-todo-p)))
         (n+1 (if repetition-n (+ 1 (string-to-number (substring repetition-n (- (length repetition-n) 1) (length repetition-n)))) 0))
         (spaced-repetition-p (alist-get n+1 spaced-rep-map))
         (new-repetition-tag (concat "repetition" (number-to-string n+1)))
         (new-tags (reverse (if repetition-n
                                (seq-reduce
                                 (lambda (a x) (if (string-equal x repetition-n) (cons new-repetition-tag a) (cons x a)))
                                 tags
                                 '())
                              (seq-reduce
                               (lambda (a x) (if (string-equal x spaced-key) (cons new-repetition-tag (cons x a)) (cons x a)))
                               tags
                               '())))))
    (if (and spaced-todo-p spaced-repetition-p)
        (progn
          ;; avoid infinitive looping
          (remove-hook 'org-trigger-hook 'my/space-repeat-if-tag-spaced)
          ;; reset to previous state
          (org-call-with-arg 'org-todo 'left)
          ;; schedule to next spaced repetition
          (org-schedule nil (alist-get n+1 spaced-rep-map))
          ;; rewrite local tags
          (org-set-tags-to new-tags)
          (add-hook 'org-trigger-hook 'my/space-repeat-if-tag-spaced))
      )))

(add-hook 'org-trigger-hook 'my/space-repeat-if-tag-spaced)


;; Org noter

(use-package org-noter
  :after org
  :ensure t
  :config
        (setq org-noter-separate-notes-from-heading t)
        (require 'org-noter-pdftools))

(use-package org-pdftools
  :ensure t
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :ensure t
  :config (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note))

(use-package org-roam-server
  :ensure t
  :config
  (setq org-roam-server-host "127.0.0.1"
        org-roam-server-port 8080
        org-roam-server-authenticate nil
        org-roam-server-export-inline-images t
        org-roam-server-serve-files nil
        org-roam-server-served-file-extensions '("pdf" "mp4" "ogv" "png" "jpg")
        org-roam-server-network-poll t
        org-roam-server-network-arrows nil
        org-roam-server-network-label-truncate t
        org-roam-server-network-label-truncate-length 60
        org-roam-server-network-label-wrap-length 20))
