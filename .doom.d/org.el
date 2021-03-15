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
      my-journal-directory (concat org-directory "journal")
      my-org-templates-directory (concat org-directory "utils/templates/")
      my-org-noter-directory (concat org-directory "reading"))

(setq org-habit-graph-column 60)



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
           (function org-journal-find-location)
           "*** TODO %i%" :empty-lines 1)

          ("j" "Journal" entry
           (function org-journal-find-location)
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
  (org-journal-file-type 'monthly)
  (org-journal-file-format "%Y-%m.org")
  (org-journal-date-format "%A, %d %B %Y")
  (org-journal-dir my-journal-directory))

;; Org journal fn for capture
(defun org-journal-find-location ()
  (org-journal-new-entry t) (goto-char (point-max)))


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
  :init
        (map! :leader
              :prefix "n"
              :desc "Noter: Yank from PDF" "p" #'org-noter-yank)
  :config
        (setq org-noter-separate-notes-from-heading t
              org-noter-notes-search-path my-org-noter-directory)
        (require 'org-noter-pdftools))


(use-package org-noter
  :config
  ;; Your org-noter config ........
  (require 'org-noter-pdftools))

(use-package org-pdftools
  :ensure t
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :ensure t
  :config

    (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note))
;;   ;; Add a function to ensure precise note is inserted
;;   (defun org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
;;     (interactive "P")
;;     (org-noter--with-valid-session
;;      (let ((org-noter-insert-note-no-questions (if toggle-no-questions
;;                                                    (not org-noter-insert-note-no-questions)
;;                                                  org-noter-insert-note-no-questions))
;;            (org-pdftools-use-isearch-link t)
;;            (org-pdftools-use-freestyle-annot t))
;;        (org-noter-insert-note (org-noter--get-precise-info)))))

;;   ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
;;   (defun org-noter-set-start-location (&optional arg)
;;     "When opening a session with this document, go to the current location.
;; With a prefix ARG, remove start location."
;;     (interactive "P")
;;     (org-noter--with-valid-session
;;      (let ((inhibit-read-only t)
;;            (ast (org-noter--parse-root))
;;            (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
;;        (with-current-buffer (org-noter--session-notes-buffer session)
;;          (org-with-wide-buffer
;;           (goto-char (org-element-property :begin ast))
;;           (if arg
;;               (org-entry-delete nil org-noter-property-note-location)
;;             (org-entry-put nil org-noter-property-note-location
;;                            (org-noter--pretty-print-location location))))))))
;;   (with-eval-after-load 'pdf-annot
;;     (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))

(defun pdf-view-kill-ring-save-to-file ()
  "Personal function to copy the region to a temporary file. Used
   in conjunction with quote-process.rb for further processing,
   and org-noter-yank."
  (interactive)
  ;; Delete and recreate quote-process file -- we don't want to append.
  (shell-command "rm /tmp/quote-process")
  (shell-command "touch /tmp/quote-process")
  (pdf-view-assert-active-region)
  (let* ((txt (pdf-view-active-region-text)))
    (pdf-view-deactivate-region)
    (write-region
     (mapconcat 'identity txt "\n") nil "/tmp/quote-process" 'append)))

(defun org-noter-yank ()
  "Send highlighted region of PDF to Org-noter note."
  (interactive)
  (setq inhibit-message t) ;; Avoid annoying messages
  (pdf-view-kill-ring-save-to-file)
  (shell-command (concat "ruby ~/.doom.d/clean-pdf-quote.rb"))
  (setq quote-process
        (file-string "/tmp/quote-process"))
  (kill-new quote-process)
  (org-noter-insert-note-toggle-no-questions)
  (org-yank)
  (fill-paragraph)
  (setq inhibit-message nil))
