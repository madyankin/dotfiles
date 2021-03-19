;;; org.el -*- lexical-binding: t; -*-

(global-set-key (kbd "s-=") 'org-capture)

(require 'org-habit)
(require 'org-drill)

(setq org-bullets-bullet-list '("·")
      org-support-shift-select t
      org-catch-invisible-edits 'smart
      org-log-done 'time
      org-log-into-drawer t
      org-agenda-start-with-log-mode t
      org-directory "~/Dropbox/Org/"
      org-link-file-path-type 'relative
      org-agenda-files (directory-files-recursively "~/Dropbox/Org/" "\\.org$")
      org-todo-keywords '((sequence "TODO(t)" "WAIT(w@/!)" "|" "DONE(d!)" "CANCELED(c@)"))
      org-habit-show-habits t

      org-drill-scope 'directory

      my-zettelkasten-directory (concat org-directory "zettelkasten")
      my-journal-directory org-directory
      my-org-templates-directory (concat org-directory "utils/templates/")
      my-org-noter-directory (concat org-directory "reading")

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
  (org-journal-file-type 'yearly)
  (org-journal-file-format "journal.org")
  (org-journal-date-format "%A, %d %B %Y")
  (org-journal-dir my-journal-directory))



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


(use-package! anki-editor
  :after or
  :config
  (setq anki-editor-create-decks 't))

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
        (setq org-noter-separate-notes-from-heading t
              org-noter-notes-search-path my-org-noter-directory)
        (require 'org-noter-pdftools))

(use-package org-pdftools
  :ensure t
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :ensure t
  :config (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note))


