;;; tabby-mode.el --- Minor mode for the Tabby AI coding assistant -*- lexical-binding: t -*-

;; Copyright (C) 2023 Authors
;; SPDX-License-Identifier: Apache-2.0

;; Author: Ragnar Dahlén <r.dahlen@gmail.com>
;; URL: https://github.com/ragnard/tabby-mode
;; Package-Requires: ((emacs "25.1"))
;; Package-Version: 20240107.2124
;; Package-Revision: b656727247c5
;; Keywords: tools, convenience

;;; Commentary:

;; This package provides a simple integration with the Tabby AI coding
;; assistant. A single interactive function, `tabby-complete`, can be
;; used to send the coding context to a Tabby API instance, and select
;; a suggested code change.

;;; Code:

(require 'json)
(require 'subr-x)
(require 'url)
(require 'url-http)


(eval-when-compile
  (defvar url-http-end-of-headers))

(defgroup tabby nil
  "Minor mode for the Tabby AI coding assistant."
  :link '(url-link "htps://tabby.tabbyml.com")
  :group 'programming)

(defcustom tabby-api-url nil
  "URL to Tabby API."
  :type 'string
  :group 'tabby)

(defcustom tabby-auth-token nil
  "Authentication token for Tabby server."
  :type 'string
  :group 'tabby)

(defcustom tabby-mode-language-alist
  '((c-mode . "c")
    (c++-mode . "cpp")
    (go-mode . "go")
    (java-mode . "java")
    (javascript-mode . "javascript")
    (kotlin-mode . "kotlin")
    (python-mode . "python")
    (ruby-mode . "ruby")
    (rust-mode . "rust")
    (typescript-mode . "typescript")
    (yaml-mode . "yaml"))
  "Mapping from major mode to Tabby language identifier."
  :type '(alist :key-type symbol :value-type string)
  :group 'tabby)

(defvar tabby-suggestions '()
  "Completion suggestions returned by Tabby")

(defvar current-suggestion-index 0
  "Index of the current suggestion being displayed")

(defvar tabby-inline-overlay nil
  "Overlay for displaying suggestions")

(defun tabby--show-suggestion-overlay (suggestion)
  "Show suggestion overlay as grayed out text after the cursor"
  (when tabby-inline-overlay
    (delete-overlay tabby-inline-overlay))
  (setq tabby-inline-overlay (make-overlay (point) (point)))
  (overlay-put tabby-inline-overlay 'after-string
	       (propertize suggestion 'face '(:foreground "gray" :slant italic))))

(defun tabby-toggle-suggestion ()
  "Change displayed suggestion to the next one from the list"
  (interactive)
  (if (null tabby-suggestions)
      (message "no suggestions provided")
    (setq current-suggestion-index
	  (mod (1+ current-suggestion-index) (length tabby-suggestions)))
    (tabby--show-suggestion-overlay (nth current-suggestion-index tabby-suggestions))))

(defun tabby-accept-suggestion ()
  "Accept the currently displayed suggestion and put it into the buffer"
  (interactive)
  (when (and tabby-suggestions tabby-inline-overlay)
    (let ((suggestion (nth current-suggestion-index tabby-suggestions)))
      (insert suggestion)
      (delete-overlay tabby-inline-overlay)
      (setq tabby-inline-overlay nil)
      (setq tabby-suggestions nil)
      (setq current-suggestion-index 0))))


(defun tabby-clear-suggestion ()
  "Clear currently displayed suggestion without accepting it"
  (interactive)
  (when tabby-inline-overlay
    (delete-overlay tabby-inline-overlay)
    (setq tabby-inline-overlay nil)))


(defun tabby--completions-url ()
  "Return the API url for completions."
  (format "%s/v1/completions" (string-remove-suffix "/" tabby-api-url)))

(defun tabby--completions-request (lang prefix suffix)
  "Build a completions request for LANG with PREFIX and SUFFIX."
  `((language . ,lang)
    (segments . ((prefix . ,prefix)
                 (suffix . ,suffix)))))

	  
(defun tabby--get-completions (buffer lang prefix suffix callback)
  (let* (
	 (request-body (tabby--completions-request lang prefix suffix))
	 (url-request-method "POST")
	 (url-request-extra-headers `(("Content-Type" . "application/json")
				      ("Accept" . "application/json")
				      ("Authorization" . ,(format "access_token %s" tabby-auth-token))))
	 (url-request-data (json-encode request-body)))
    (url-retrieve (tabby--completions-url)
     (lambda (_status)
       (goto-char url-http-end-of-headers)
       (let ((response (json-read)))
	 (funcall callback buffer response))))))


(defun tabby--handle-completion-response (buffer response)
  "Handle a completions RESPONSE for a BUFFER."
  (setq tabby-suggestions (mapcar (lambda (c)
				    (alist-get 'text c))
				  (alist-get 'choices response)))
  (setq current-suggestion-index -1)
  (with-current-buffer buffer
    (tabby-toggle-suggestion)
    (redisplay)))


(defun tabby--determine-language ()
  "Determine the language identifier for the current buffer.
See https://code.visualstudio.com/docs/languages/identifiers."
  (alist-get major-mode tabby-mode-language-alist))

(defun tabby-complete ()
  "Ask Tabby for completion suggestions for the text around point."
  (interactive)
  (when (not tabby-api-url)
    (error "Please configure the URL for your Tabby server. See customizable variable `tabby-api-url`"))
  (when (not tabby-auth-token)
    (error "Please configure the authorization token for your Tabby server. See customizable variable `tabby-auth-token`"))
  (let* ((lang (tabby--determine-language))
         (prefix (buffer-substring-no-properties (point-min) (point)))
         (suffix (unless (eobp)
                   (buffer-substring-no-properties (+ (point) 1) (point-max)))))
    (if lang
        (tabby--get-completions (current-buffer) lang prefix suffix 'tabby--handle-completion-response)
      (message "Unable to determine language for current buffer."))))

(define-minor-mode tabby-mode
  "A minor mode for the Tabby AI coding assistant."
  :keymap '((["C-<tab>"] . tabby-complete)
	    (["C-c a"] . tabby-accept-suggestion)
	    (["C-c t"] . tabby-toggle-suggestion)
	    (["C-c c"] . tabby-clear-suggestion)))

(provide 'tabby-mode)

;;; tabby-mode.el ends here

