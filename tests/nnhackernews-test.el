;;; nnhackernews-test.el --- Test utilities for nnhackernews  -*- lexical-binding: t; coding: utf-8 -*-

;; The following is a derivative work of
;; https://github.com/millejoh/emacs-ipython-notebook
;; licensed under GNU General Public License v3.0.

(custom-set-default 'gnus-home-directory (concat default-directory "tests"))
(custom-set-default 'message-directory (concat default-directory "tests/Mail"))
(custom-set-default 'request-storage-directory (concat default-directory "tests/request"))
(custom-set-variables
 `(auth-sources (quote ,(list (concat (file-name-as-directory gnus-home-directory) ".netrc"))))
 '(auto-revert-verbose nil)
 '(auto-revert-stop-on-user-input nil)
 '(gnus-read-active-file nil)
 '(gnus-batch-mode t)
 '(gnus-use-dribble-file nil)
 '(gnus-read-newsrc-file nil)
 '(gnus-save-killed-list nil)
 '(gnus-save-newsrc-file nil)
 '(gnus-secondary-select-methods (quote ((nnhackernews ""))))
 '(gnus-select-method (quote (nnnil)))
 '(gnus-message-highlight-citation nil)
 '(gnus-verbose 8)
 '(request-log-level (quote debug))
 '(auth-source-debug 'trivia)
 '(gnus-large-ephemeral-newsgroup 4000)
 '(gnus-large-newsgroup 4000)
 '(gnus-interactive-exit (quote quiet)))

(with-eval-after-load 'request
  (defun request--safe-delete-files (&rest args)))

(require 'nnhackernews)
(require 'ert)
(require 'message)

(defun nnhackernews-test-wait-for (predicate &optional predargs ms interval continue)
  "Wait until PREDICATE function returns non-`nil'.
  PREDARGS is argument list for the PREDICATE function.
  MS is milliseconds to wait.  INTERVAL is polling interval in milliseconds."
  (let* ((int (aif interval it (aif ms (max 300 (/ ms 10)) 300)))
         (count (max 1 (if ms (truncate (/ ms int)) 25))))
    (unless (or (cl-loop repeat count
                         when (apply predicate predargs)
                         return t
                         do (sleep-for 0 int))
                continue)
      (error "Timeout: %s" predicate))))

(defun nnhackernews-test-recording-file (scenario)
  (concat (file-name-as-directory (directory-file-name load-file-name))
          "recording." scenario))

;; if yes-or-no-p isn't specially overridden, make it always "yes"
(let ((original-yes-or-no-p (symbol-function 'yes-or-no-p)))
  (add-function :around (symbol-function 'message-cancel-news)
                (lambda (f &rest args)
                  (if (not (eq (symbol-function 'yes-or-no-p) original-yes-or-no-p))
                      (apply f args)
                    (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest args) t)))
                      (apply f args))))))

(add-function
 :filter-args (symbol-function 'read-string)
 (lambda (args)
   (when (string-match-p "\\buser\\b" (car args))
     (setf (nthcdr 3 args) (list (getenv "HNUSER"))))
   args))

(add-function
 :filter-args (symbol-function 'read-passwd)
 (lambda (args)
   (when (string-match-p "\\bPassword for\\b" (car args))
     (cond ((>= (length args) 2)
            (setf (nthcdr 2 args) (list (getenv "HNPASSWORD"))))
           (t (setf (nthcdr 1 args) (list nil (getenv "HNPASSWORD"))))))
   args))

(provide 'nnhackernews-test)
