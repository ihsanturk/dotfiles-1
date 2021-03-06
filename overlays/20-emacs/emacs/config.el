;;; init.el --- Gaelan's Emacs config -*- lexical-binding: t; eval: (view-mode 1) -*-

(let ((minver "26.1"))
  (when (version< emacs-version minver)
    (error "Your Emacs is too old -- this config requires v%s or higher" minver)))

(let ((normal-gc-cons-threshold (* 20 1024 1024))
      (init-gc-cons-threshold (* 128 1024 1024)))
  (setq gc-cons-threshold init-gc-cons-threshold)
  (add-hook 'emacs-startup-hook
	    (lambda () (setq gc-cons-threshold normal-gc-cons-threshold))))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(setq user-full-name "Gaelan D'costa"
      user-mail-address "gdcosta@gmail.com")

(eval-when-compile
  (require 'cl-lib))

(defconst gaelan/*is-osx* (eq system-type 'darwin))
(defconst gaelan/*is-linux* (eq system-type 'gnu/linux))

;; Font faces
(defvar gaelan/default-font-face "CamingoCode")
(defvar gaelan/default-variable-font-face "Lato")

;; Font sizes, divide by 10 to get point size.
(defvar gaelan/default-font-size 130)
(defvar gaelan/default-variable-font-size 130)

;; Make frame transparency overridable
(defvar gaelan/frame-transparency '(90 . 90))

(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives
	     '("org" . "https://orgmode.org/elpa/"))

(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(require 'use-package-ensure)
(setq use-package-always-ensure t)

(use-package diminish)

(use-package bind-key)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Don't show Emacs' default splash screen
(setq inhibit-splash-screen t)

;; Set frame transparency
(set-frame-parameter (selected-frame) 'alpha gaelan/frame-transparency)
(add-to-list 'default-frame-alist `(alpha . ,gaelan/frame-transparency))
(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(column-number-mode +1)

(set-fringe-mode 10)

(setq visual-bell t)

(global-display-line-numbers-mode t)

;; Disable line numbers for some modes
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		treemacs-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(defun gaelan/set-font-faces ()
  (set-face-attribute 'default nil :font gaelan/default-font-face :height gaelan/default-font-size)
  ;; Set the fixed font face and height
  (set-face-attribute 'fixed-pitch nil :font gaelan/default-font-face :height gaelan/default-font-size)
  ;; Set the variable font face and height
  (set-face-attribute 'variable-pitch nil :font gaelan/default-variable-font-face :height gaelan/default-variable-font-size))

;; Starting emacs as a daemon confuses things because it doesn't necessarily know
;; it will be used in a GUI, which makes certain configuration calls misbehave since
;; they are run before an Emacs frame is launched.
;;
;; So here we set up fonts/icons immediately if we're not running as a daemon, and we
;; set up a special hook if we are running as a daemon.
(if (daemonp)
    (add-hook 'server-after-make-frame-hook
              (lambda ()
                (setq doom-modeline-icon t)
                (gaelan/set-font-faces)))
  (gaelan/set-font-faces))

(use-package all-the-icons)

(use-package doom-modeline
  :custom
  (doom-modeline-height 21)
  (doom-modeline-buffer-file-name 'truncate-upto-project)
  :init
  (doom-modeline-mode 1))

(use-package rebecca-theme
  :config
  (if (daemonp)
    ;; We need this hack because when you initialize emacs as a daemon,
    ;; no frame is created so a lot of important theme loading computations
    ;; do not get run. However, this is especially hacky because we don't
    ;; want to reload the theme from scratch on every frame creation but
    ;; that's the only hook we can do this, so our hook has to remove itself
    ;; when it is done.
    (cl-labels ((load-my-theme (frame)
                               (with-selected-frame frame
                                 (load-theme 'rebecca t))
                               (remove-hook 'after-make-frame-functions #'load-my-theme)))
      (add-hook 'after-make-frame-functions #'load-my-theme))
  (load-theme 'rebecca t)))

(setq backup-directory-alist `(("." . "~/.emacs.d/backups"))
      delete-old-versions t
      kept-new-versions 8
      kept-old-versions 2
      version-control t)

(defalias 'yes-or-no-p 'y-or-n-p)

(setq vc-follow-symlinks t)

(global-set-key (kbd "s-u") 'revert-buffer)

(global-set-key (kbd "s-o") 'other-window)

(global-auto-revert-mode +1)

(use-package which-key
  :custom (which-key-idle-delay 1)
  :diminish which-key-mode
  :init
  (which-key-mode))

(use-package helpful
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key)
  ("C-c C-d" . helpful-at-point))

(use-package async
  :config
  (dired-async-mode))

(setq fill-column 80)

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

(setq-default mac-command-modifier 'meta)
(setq-default mac-option-modifier 'super)

(use-package pinentry
  :custom
  (epa-pinentry-mode 'loopback)
  :config
  (pinentry-start))

(use-package helm
  ;; Add recommended keybindings as found in Thierry Volpiatto's guide
  ;; http://tuhdo.github.io/helm-intro.html
  :bind (("M-x" . helm-M-x)
	 ("C-x C-f" . helm-find-files)
	 ("C-x r b" . helm-filtered-bookmarks)
	 ("C-x C-b" . helm-mini)
	 ("M-y" . helm-show-kill-ring)
	 ("M-i" . helm-semantic-or-imenu)
	 ("M-s o" . helm-occur)
	 ("C-h SPC" . helm-all-mark-rings)
	 ("C-x c h r" . helm-register)
	 ("C-x c h g" . helm-google-suggest)
	 ("C-c h M-:" . helm-eval-expression-with-eldoc))
  :init
  ;; Turn on fuzzy matching in a bunch of places
  ;; turn it off if it is irritating or slows down searches.
  (setq-default helm-recentf-fuzzy-match t
		helm-buffers-fuzzy-matching t
		helm-locate-fuzzy-match t
		helm-M-x-fuzzy-match t
		helm-semantic-fuzzy-match t
		helm-imenu-fuzzy-match t
		helm-apropos-fuzzy-match t
		helm-lisp-fuzzy-completion t
		helm-session-fuzzy-match t
		helm-etags-select t)
  :config
  (require 'helm-config)
  (helm-mode +1)
  (add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)

  ;; Add helmized history searching functionality for a variety of
  ;; interfaces: `eshell`, `shell-mode`, `minibuffer`,
  ;; using the same C-c C-l binding.
  (add-hook 'eshell-mode-hook
	    #'(lambda ()
		(define-key 'eshell-mode-map (kbd "C-c C-l") #'helm-eshell-history)))
  (add-hook 'shell-mode-hook
	    #'(lambda ()
		(define-key 'shell-mode-map (kbd "C-c C-l") #'helm-comint-input-ring)))
  (define-key minibuffer-local-map (kbd "C-c C-l") #'helm-minibuffer-history))

(use-package helm-ls-git
  :after helm
  :config
  ;; `helm-source-ls-git' must be defined manually
  ;; See https://github.com/emacs-helm/helm-ls-git/issues/34
  (setq helm-source-ls-git
	(and (memq 'helm-source-ls-git helm-ls-git-default-sources)
	     (helm-make-source "Git files" 'helm-ls-git-source
	       :fuzzy-match helm-ls-git-fuzzy-match)))
  (push 'helm-source-ls-git helm-mini-default-sources))

(use-package helm-descbinds
  :after helm
  :config
  (helm-descbinds-mode))

(use-package projectile
  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (projectile-mode +1))

(use-package helm-projectile
  :after helm
  :config
  (helm-projectile-on))

(use-package projectile-ripgrep
  :after projectile)

(use-package helm-rg
  :after helm)

(use-package treemacs)

(use-package treemacs-projectile
  :after projectile)

(use-package treemacs-magit
  :after magit)

(use-package flycheck
  :init
  (add-hook 'after-init-hook 'global-flycheck-mode))

(use-package yasnippet-snippets)
(use-package yasnippet
  :after yasnippet-snippets
  :config
  (yas-global-mode 1))

(use-package company
  :init
  (add-hook 'after-init-hook 'global-company-mode)
  :bind (("M-TAB" . 'company-complete)))

(use-package helm-company
  :after (helm company)
  :config
  (define-key company-mode-map (kbd "C-:") 'helm-company)
  (define-key company-active-map (kbd "C-:") 'helm-company))

(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
	 ("C->" . mc/mark-more-like-this)
	 ("C-<" . mc/mark-previous-like-this)
	 ("C-c C-<" . mc/mark-all-like-this)))

(use-package direnv
  :config
  (direnv-mode))

(use-package nix-sandbox
  :after flycheck
  :config
  ; (setq flycheck-command-wrapper-function
  ;      (lambda (command) (apply 'nix-shell-command (nix-current-sandbox) command))
  ;      flycheck-executable-find
  ;      (lambda (cmd) (nix-executable-find (nix-current-sandbox) cmd))))
  )
(use-package helm-nixos-options
  :after helm
  :if gaelan/*is-linux*
  :bind (("C-c C-S-n" . helm-nixos-options)))

(use-package company-nixos-options
  :if gaelan/*is-linux*
  :after company
  :config (add-to-list 'company-backends 'company-nixos-options))

(use-package nov
  :mode ("\\.epub\\'" . nov-mode))

(defconst gaelan/webdav-prefix
  (if gaelan/*is-osx*
      (file-name-as-directory "~/Seafile/DocStore/")
    (file-name-as-directory "~/fallcube/DocStore/"))
  "The root location of my emacs / org-mode files system")

(defconst gaelan/brain-prefix
  (concat gaelan/webdav-prefix "brain/")
  "The root directory of my org-roam knowledge store.")

(defconst gaelan/gtd-prefix
  (concat gaelan/brain-prefix "gtd/")
  "The root directory of my GTD task management system.")

(defun gaelan/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode))

(use-package org
  :pin org
  :hook
  (org-mode . gaelan/org-mode-setup)
  :custom
  ;; Have prettier chrome for headlines that can be expanded
  (org-ellipsis " ▾")
  ;; Show task state change logs in agenda mode
  (org-agenda-start-with-log-mode  t)
  ;; When we finish a task, log the time
  (org-log-done 'time)
  ;; Store task state changes into a dedicated drawer
  (org-log-into-drawer t)

  ;; The workhorse files in my GTD system
  (org-agenda-files
   `(,(concat gaelan/gtd-prefix "gtd.org")
     ,(concat gaelan/gtd-prefix "tickler.org")
     ,(concat gaelan/gtd-prefix "gcal/personal.org")
     ,(concat gaelan/gtd-prefix "gcal/work.org")))

  ;; Things I want to quickly enter, tasks and journal entries
  (org-capture-templates
   `(("t" "Todo" entry (file+headline ,(concat gaelan/gtd-prefix "gtd.org") "Inbox")
      "* TODO %?")
     ("p" "Project" entry (file+headline ,(concat gaelan/gtd-prefix "gtd.org") "Inbox")
      "* [/] %? :project:")
     ("d" "Daily Morning Reflection" entry (function gaelan/org-journal-find-location)
      "* %(format-time-string org-journal-time-format)Daily Morning Reflection\n** Things that will be achieved today\n     - [ ] %?\n** What am I grateful for?\n")
     ("e" "Daily Evening Reflection" entry (function gaelan/org-journal-find-location)
      "* %(format-time-string org-journal-time-format)Daily Evening Reflection\n** What things did I accomplish today?\n   1. %?\n** What did I learn?\n** What did I do to help my future?\n** What did I do to help others?\n")
     ("w" "Weekly Reflection" entry (function gaelan/org-journal-find-location)
      "* %(format-time-string org-journal-time-format)Weekly Reflection\n** What were you grateful for this week? Pick one and go deep.\n   %?\n** What were your biggest wins this week?\n** What tensions are you feeling this week? What is causing these tensions?\n** What can wait to happen this week? What can you work on this week?\n** What can you learn this week?")
     ("m" "Monthly Reflection" entry (function gaelan/org-journal-find-location)
      "* %(format-time-string org-journal-time-format)Monthly Reflection\n** What were your biggest wins of the month?\n   - %?\n** What were you most grateful for this month?\n** What tensions have you removed this month?\n** What did you learn this month?\n** How have you grown this month?")
     ("y" "Yearly Reflection" entry (function gaelan/org-journal-find-location)
      "* %(format-time-string) org-journal-time-format)Yearly Reflection\n** What were your biggest wins of the year?\n   - %?\n** What were you most grateful for this year?\n** What tensions have you removed this year?\n** What did you learn this year?\n** How have you grown this year?")))

  ;; Where do I tend to move files to?
  (org-refile-targets
   `((,(concat gaelan/gtd-prefix "gtd.org") . (:maxlevel . 2))
     (,(concat gaelan/gtd-prefix "someday.org") . (:level . 1))
     (,(concat gaelan/gtd-prefix "tickler.org") . (:level . 1))
     ;; Move targets within a file
     (nil . (:level . 1))))

  ;; Handy search views for agenda mode
  (org-agenda-custom-commands
   '(("n" "Next Actions"
      ((todo "NEXT")))
     ("p" "Unplanned Projects"
      ((todo "PLAN")))
     ("r" "Reoccuring Tasks"
      ((tags-todo "+CATEGORY=\"tickler\"")))
     ("i" "Inbox Items"
      ((tags-todo "+CATEGORY=\"Inbox\"")))))

  :config
  ;; Save Org buffers after refiling!
  (advice-add 'org-refile :after 'org-save-all-org-buffers)

  :bind
  (("C-c l" . org-store-link)
   ("C-c a" . org-agenda)
   ("C-c c" . org-capture)))

(use-package visual-fill-column
  :init
  (defun gaelan/org-mode-visual-fill ()
    (setq visual-fill-column-width 100
          visual-fill-column-center-text t)
    (visual-fill-column-mode 1))
  :after org
  :hook
  (org-mode . gaelan/org-mode-visual-fill))

(use-package org-habit
  :ensure nil
  :after org
  :custom
  (org-habit-graph-column 60)
  :init
  (add-to-list 'org-modules 'org-habit))

(use-package org-roam
  :bind (:map org-roam-mode-map
	      ("C-c n l" . org-roam)
	      ("C-c n f" . org-roam-find-file)
	      ("C-c n g" . org-roam-graph-show)
	      :map org-mode-map
	      ("C-c n i" . org-roam-insert)
	      ("C-c n I" . org-roam-insert-immediate))
  :custom
  (org-roam-directory gaelan/brain-prefix)
  (org-roam-db-location (if gaelan/*is-osx*
			    (concat org-roam-directory "/db/osx.db")
			  (concat org-roam-directory "/db/linux.db")))

  (org-roam-completion-system 'helm)
  ;; I don't care about graphing daily notes, tasks, or historical stuff
  (org-roam-graph-exclude-matcher '("journal" "gtd"))
  (org-roam-capture-templates
   '(("d" "default" plain (function org-roam--capture-get-point)
      "%?"
      :file-name "%<%Y%m%d%H%M%S>-${slug}"
      :head "#+title: ${title}\n"
      :unnarrowed t)
     ("f" "fleeting" plain (function org-roam--capture-get-point)
      "%?"
      :file-name "%<%Y%m%d%H%M%S>-${slug}"
      :head "#+title: ${title}\n#+roam_tags: fleeting-note\n"
      :unnarrowed t)
     ("l" "literature" plain (function org-roam--capture-get-point)
      "%?"
      :file-name "%<%Y%m%d%H%M%S>-${slug}"
      :head "#+title: ${title}\n#+roam_tags: literature-note\n"
      :unnarrowed t)))
  :config
  (add-hook 'after-init-hook 'org-roam-mode)
  ;;  org-roam-protocol is used to handle weblinks (e.g. org-roam-server)
  (require 'org-roam-protocol))

(use-package org-roam-server
  :after org-roam
  :config
  (setq org-roam-server-host "127.0.0.1"
	org-roam-server-port 8080
	org-roam-server-export-inline-images t
	org-roam-server-authenticate nil
	org-roam-server-network-poll t
	org-roam-server-network-arrows nil
	org-roam-server-network-label-truncate t
	org-roam-server-network-label-truncate-length 60
	org-roam-server-network-label-wrap-length 20))

(use-package deft
  :after org
  :bind ("C-c n d" . deft)
  :custom
  (deft-recursive t)
  (deft-use-filter-string-for-filename t)
  (deft-default-extension "org")
  (deft-directory (concat gaelan/brain-prefix)))

(winner-mode +1)

(use-package org-journal
  :after org
  :bind ("C-c n j" . org-journal-new-entry)
  :custom
  (org-journal-date-format "%A, %F")
  (org-journal-dir (file-name-as-directory (concat gaelan/webdav-prefix "brain/" "journal")))
  (org-journal-file-format "%Y/%m/%Y-%m-%d.org"))

(defun gaelan/org-journal-find-location ()
  ;; Open today's journal, but specify a non-nil prefix argument in order to
  ;; inhibit inserting the heading; org-capture will insert the heading.
  (org-journal-new-entry t)
  ;; Position point on the journal's top-level heading so that org-capture
  ;; will add the new entry as a child entry.
  (goto-char (point-min)))

(use-package org-noter)

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode))

(defun gaelan/org-replace-link-by-link-description ()
  "Replace an org link by its description; or if empty, its address.

   Source: https://emacs.stackexchange.com/questions/10707/in-org-mode-how-to-remove-a-link
   and modified slightly to place the url in the kill ring."
  (interactive)
  (if (org-in-regexp org-link-bracket-re 1)
      (save-excursion
	(let ((remove (list (match-beginning 0) (match-end 0)))
	      (description (if (match-end 3)
			       (org-match-string-no-properties 3)
			     (org-match-string-no-properties 1))))
	  (apply 'kill-region remove)
	  (insert description)))))

;; Automatically tangle our Emacs.org config file when we save it
(defun gaelan/org-babel-tangle-config ()
  (when (string-equal (file-name-directory (buffer-file-name))
		      (expand-file-name user-emacs-directory))
    ;; Dynamic scoping to the rescue
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'gaelan/org-babel-tangle-config)))

(use-package magit
  ;; I should have a keybinding that displays magit-status from anywhere
  :bind (("C-x g" . magit-status))
  :config
  ;; Enable pseudo-worktree for uncommitted files.
  (require 'magit-wip)
  (magit-wip-mode))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  ;; Enable some built-in LSP clients
  :hook (go-mode . lsp-deferred))

(use-package lsp-ui
  :after lsp-mode)

(use-package lsp-treemacs
  :after lsp-mode
  :config
  (lsp-treemacs-sync-mode +1))

(use-package helm-lsp)

(use-package dap-mode
  :config (dap-auto-configure-mode))

(use-package docker
  :bind ("C-c d" . docker))

(use-package docker-tramp)

(use-package rainbow-delimiters)

(show-paren-mode)

(use-package smartparens
  :config
  (require 'smartparens-config)
  (sp-use-smartparens-bindings))

(defun gaelan/generic-lisp-mode-hook ()
  "Mode hook when working in any Lisp."
  ;; Unlike non-lispy editing modes, we should never allow unbalanced parens
  (smartparens-strict-mode)
  ;; Enable visual disambiguation of nested parentheses
  (rainbow-delimiters-mode)
  ;; Show documentation for a function/variable in the minibuffer
  (turn-on-eldoc-mode))

(use-package sly)
(use-package sly-quicklisp)

(use-package helm-sly
  :after (sly helm-company)
  :config
  (add-hook 'sly-mrepl-hook #'company-mode)
  ; (define-key sly-mrepl-mode-map (kbd "<tab>") 'helm-company)
  )

(setq inferior-lisp-program "sbcl")

(add-hook 'lisp-mode-hook 'gaelan/generic-lisp-mode-hook)

(add-hook 'emacs-lisp-mode-hook 'gaelan/generic-lisp-mode-hook)

(define-key emacs-lisp-mode-map (kbd "C-c C-c") 'eval-defun)
(define-key emacs-lisp-mode-map (kbd "C-c C-p") 'eval-print-last-sexp)
(define-key emacs-lisp-mode-map (kbd "C-c C-r") 'eval-region)
(define-key emacs-lisp-mode-map (kbd "C-c C-k") 'eval-buffer)
(define-key emacs-lisp-mode-map (kbd "C-c C-l") 'load-file)
(define-key emacs-lisp-mode-map (kbd "C-c RET") 'macroexpand-1)
(define-key emacs-lisp-mode-map (kbd "C-c M-m") 'macroexpand-all)

(use-package clojure-mode
  :config
  (add-hook 'clojure-mode-hook #'gaelan/generic-lisp-mode-hook)
  (add-hook 'clojure-mode-hook #'subword-mode))

(use-package cider
  :config
  (add-hook 'cider-repl-mode-hook #'gaelan/generic-lisp-mode-hook)
  (add-hook 'cider-repl-mode-hook #'subword-mode))

(use-package helm-cider
  :after helm)

(defun gaelan/clj-refactor-hook ()
  (clj-refactor-mode 1)
  (yas-minor-mode 1)
  (cljr-add-keybindings-with-prefix "C-c C-m"))

(use-package clj-refactor
  :config
  (add-hook 'clojure-mode-hook #'gaelan/clj-refactor-hook))

(use-package flycheck-clj-kondo
  :after clojure-mode)

(use-package cider-eval-sexp-fu)

(use-package kaocha-runner
  :bind ((:map clojure-mode-map
	       ("C-c k t" . kaocha-runner-run-test-at-point)
	       ("C-c k r" . kaocha-runner-run-tests)
	       ("C-c k a" . kaocha-runner-run-all-tests)
	       ("C-c k w" . kaocha-runner-show-warnings)
	       ("C-c k h" . kaocha-runner-hide-windows))))

(use-package go-mode)

(use-package pyenv-mode
  :config
  (add-hook 'python-mode 'pyenv-mode))

(use-package anaconda-mode
  :config
  (add-hook 'python-mode-hook 'anaconda-mode)
  (add-hook 'python-mode-hook 'anaconda-eldoc-mode))

(use-package company-anaconda
  :after company
  :config
  (add-to-list 'company-backends '(company-anaconda :with company-capf)))

(use-package lsp-haskell
  :hook (haskell-mode-hook . lsp-deferred))

(use-package rustic)

(use-package terraform-mode)

(use-package company-terraform
  :after company
  :config
  (company-terraform-init))

(use-package yaml-mode)

(use-package nix-mode)

(defun gaelan/run-in-background (command)
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

(defun gaelan/set-wallpaper ()
  (interactive)
  (start-process-shell-command
   "feh" nil "feh --bg-scale ~/Pictures/Wallpaper/Vapourwave.jpg"))

(defun gaelan/exwm-init-hook ()
  ;; Make workspace 1 be the one which we activate at startup
  (exwm-workspace-switch-create 1)

  ;; Start our dashboard panel
  ;; (gaelan/start-panel)

  ;; Launch apps that will run in the background
  (gaelan/run-in-background "dunst")
  (gaelan/run-in-background "nm-applet")
  (gaelan/run-in-background "pasystray")
  (gaelan/run-in-background "blueman-applet"))

(defun gaelan/exwm-update-title-hook ()
  "EXWM hook for renaming buffer names to their associated X window title."

  (pcase exwm-class-name
    ("Firefox" (exwm-workspace-rename-buffer
                (format "Firefox: %s" exwm-title)))))

(defun gaelan/exwm-update-class-hook ()
  "EXWM hook for renaming buffer names to their associated X window class."
  (exwm-workspace-rename-buffer exwm-class-name))

(defun gaelan/exwm-randr-screen-change-hook ()
  (gaelan/run-in-background "autorandr --change --force")
  (gaelan/set-wallpaper)
  (message "Display config: %s"
           (string-trim (shell-command-to-string "autorandr --current"))))

(when gaelan/*is-linux*
  (use-package exwm
    :bind
    (:map exwm-mode-map
          ;; C-q will enable the next key to be sent directly
          ([?\C-q] . 'exwm-input-send-next-key))
    :config
    ;; Set default number of workspaces
    (setq exwm-workspace-number 5)

    ;; Set up management hooks
    (add-hook 'exwm-update-class-hook
              #'gaelan/exwm-update-class-hook)
    (add-hook 'exwm-update-title-hook
              #'gaelan/exwm-update-title-hook)
    ;; (add-hook 'exwm-manage-finish-hook
    ;;  	      #'gaelan/exwm-manage-finish-hook)
    (add-hook 'exwm-init-hook
              #'gaelan/exwm-init-hook)

    ;; Enable multi-monitor support for EXWM
    (require 'exwm-randr)
    ;; Configure monitor change hooks
    (add-hook 'exwm-randr-screen-change-hook
              'gaelan/exwm-randr-screen-change-hook)
    (exwm-randr-enable)
    ;; Call the monitor configuration hook for the first time
    (gaelan/run-in-background "autorandr --change --force")
    (gaelan/set-wallpaper)

    ;; My workspaces includes specific ones for browsing, mail, slack
    ;; By default, workspaces show up on the first, default, active monitor.
    (setq exwm-randr-workspace-monitor-plist
          '(3 "DP-1-2" 4 "DP-1-2"))

    ;; Set up exwm's systembar since xmobar doesn't support it
    ;; Note: This has to be done before (exwm-init)
    (require 'exwm-systemtray)
    (setq exwm-systemtray-height 20)
    (exwm-systemtray-enable)

    ;; Automatically send mouse cursor to selected workspace's display
    (setq exwm-workspace-warp-cursor t)

    ;; Window focus should follow mouse pointer
    (setq mouse-autoselect-window t
          focus-follows-mouse t)

    ;; Set some global window management bindings. These always work
    ;; regardless of EXWM state.
    ;; Note: Changing this list after (exwm-enable) takes no effect.   
    (setq exwm-input-global-keys
          `(
            ;; 's-r': Reset to (line-mode).
            ([?\s-r] . exwm-reset)

            ;; Move between windows
            ([?\s-h] . windmove-left)
            ([?\s-l] . windmove-right)
            ([?\s-k] . windmove-up)
            ([?\s-j] . windmove-down)

            ;; 's-w': Switch workspace.
            ([?\s-w] . exwm-workspace-switch)
            ;; 's-b': Bring application to current workspace
            ([?\s-b] . exwm-workspace-switch-to-buffer)

            ;; s-0 is an inconvenient shortcut sequence, given 0 is before 1
            ([?\s-`] . (exwm-workspace-switch-create 0))
            ([s-escape] . (exwm-workspace-switch-create 0))

            ;; 's-p': Launch application a la dmenu
            ([?\s-p] . (lambda (command)
                         (interactive (list (read-shell-command "$ ")))
                         (start-process-shell-command command nil command)))

            ;; 's-<N>': Switch to certain workspace.
            ,@(mapcar (lambda (i)
                        `(,(kbd (format "s-%d" i)) .
                          (lambda ()
                            (interactive)
                            (exwm-workspace-switch-create ,i))))
                      (number-sequence 0 9))))

    ;; Certain important emacs keystrokes should always be handled by
    ;; emacs in preference over the application handling them
    ;; (setq exwm-input-prefix-keys
    ;; 	  '(?\C-x
    ;; 	    ?\C-u
    ;; 	    ?\C-h
    ;; 	    ?\M-x
    ;; 	    ?\M-`
    ;; 	    ?\M-&
    ;; 	    ?\M-:))

    ;; translate emacs keybindings into CUA-like ones for most apps, since most
    ;; apps don't observe emacs kebindings and we would like a uniform experience.
    (setq exwm-input-simulation-keys
          '(;; movement
            ([?\C-b] . [left])
            ([?\M-b] . [C-left])
            ([?\C-f] . [right])
            ([?\M-f] . [C-right])
            ([?\C-p] . [up])
            ([?\C-n] . [down])
            ([?\C-a] . [home])
            ([?\C-e] . [end])
            ([?\M-v] . [prior])
            ([?\C-v] . [next])
            ([?\C-d] . [delete])
            ([?\C-k] . [S-end delete])
            ;; cut/paste
            ([?\C-w] . [?\C-x])
            ([?\M-w] . [?\C-c])
            ([?\C-y] . [?\C-v])
            ;; search (this should really be a firefox-only thing)
            ([?\C-s] . [?\C-f])))

    ;; Pin certain applications to specific workspaces
    (setq exwm-manage-configurations
          '(((string= exwm-class-name "Firefox") workspace 2)
            ((string= exwm-class-name "Chromium-browser") workspace 3)
            ((string= exwm-class-name ".obs-wrapped") workspace 2)))

    ;; Enable EXWM
    (exwm-enable)))

(with-eval-after-load 'ediff-wind
  (setq ediff-control-frame-parameters
        (cons '(unsplittable . t)  ediff-control-frame-parameters)))

(when gaelan/*is-linux*
  (use-package desktop-environment
    :requires (exwm)
    :config
    (desktop-environment-mode)))

(when gaelan/*is-linux*
  (use-package helm-exwm
    :init
    (setq-default helm-source-names-using-follow '("EXWM buffers"))
    :config
    (setq helm-exwm-emacs-buffers-source (helm-exwm-build-emacs-buffers-source))
    (setq helm-exwm-source (helm-exwm-build-source))
    (push 'helm-exwm-emacs-buffers-source helm-mini-default-sources)
    (push 'helm-exwm-source helm-mini-default-sources)))
