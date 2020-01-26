;;; init-org.el --- Org mode config. -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:
(require 'init-package)

;; All my org files live in a cloud-synced directory that differ between OSX and Linux
(let ((webdav-prefix
       (if (eql system-type 'darwin)
	   (file-name-as-directory "~/Seafile/gtd/")
	 (file-name-as-directory "~/fallcube/gtd/"))))

  (gaelan/require-package 'org-journal)
  (with-eval-after-load 'org-journal
    (customize-set-variable 'org-journal-dir
			     (file-name-as-directory (concat webdav-prefix "journal/")))
    (customize-set-variable 'org-journal-file-format "%Y/%Y%m%d.org")
    ;; Bullet Journal discourages carrying over todos. Decide that explicitly!
    (customize-set-variable 'org-journal-carryover-items nil))

  ;; Prettify org mode, remove unnecessary asterix.
  (gaelan/require-package 'org-bullets)
  (with-eval-after-load 'org-bullets
    (add-hook 'org-mode-hook 'org-bullets-mode))

  (global-set-key (kbd "C-c l") 'org-store-link)
  (global-set-key (kbd "C-c a") 'org-agenda)
  (global-set-key (kbd "C-c c") 'org-capture)

  (customize-set-variable 'org-lowest-priority ?D)
  (customize-set-variable 'org-log-into-drawer t)
  (setq-default org-capture-templates
		`(("t" "Todo" entry (file+headline ,(concat webdav-prefix "gtd.org") "Tasks")
		   "* TODO %?\n   %t")))
  (setq-default org-refile-targets
		`((,(concat webdav-prefix "gtd.org") . (:level . 1))
		  (,(concat webdav-prefix "someday.org") . (:level . 1))))

  (customize-set-variable 'org-agenda-files
			   `(,(concat webdav-prefix "gtd.org")
			     ,(concat webdav-prefix "gcal/personal.org")
			     ,(concat webdav-prefix "gcal/work.org")))

  (customize-set-variable 'org-agenda-custom-commands
			  '(("h" "Office and Home Lists"
			     ((agenda)
			      (tags-todo "@home")
			      (tags-todo "@officeto")
			      (tags-todo "@officekw")
			      (tags-todo "@lappy")
			      (tags-todo "@phone")
			      (tags-todo "@brain")
			      (tags-todo "@online")
			      (tags-todo "@reading")
			      (tags-todo "@watching")
			      (tags-todo "@gaming")))
			    ("d" "Daily Action List"
			     ((agenda "" ((org-agenda-ndays 1)
					  (org-agenda-sorting-strategy
					   (quote ((agenda time-up priority-down tag-up))))
					  (org-deadline-warning-days 0)))))))

  (gaelan/require-package 'org-gcal)
  (with-eval-after-load 'org-gcal
    (let* ((bwdata (elt (bitwarden-search "offlineimap") 0))
	   (bwfields (gethash "fields" bwdata))
	   (client-id (gethash "value" (elt bwfields 0)))
	   (client-secret (gethash "value" (elt bwfields 1))))
      (customize-set-variable 'org-gcal-client-id client-id)
      (customize-set-variable 'org-gcal-client-secret client-secret))
    (customize-set-variable 'org-gcal-file-alist
			     `(("gdcosta@gmail.com" . ,(concat webdav-prefix "gtd/gcal/personal.org"))
			       ("gaelan@tulip.com" . ,(concat webdav-prefix "gtd/gcal/work.org"))))))

(provide 'init-org)
;;; init-org ends here
