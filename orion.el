;; -*- lexical-binding: t; -*-
(require 'request)
(require 'json)


(defvar orion-timer nil)
(defvar timer-interval 5)
(defvar code-suggestion nil)
(defvar delete-offset 0)
(global-set-key (kbd "C-c TAB") 'code-completion)


(defun get-line-content ()
  (concat
   "Get the content of the line "
   "where the cursor is located.")
  (buffer-substring-no-properties 
   (line-beginning-position) 
   (line-end-position)))


(defun take-code-snippet ()
  (concat
   "Get content from the beginning of the buffer "
   "to the cursor position.")
  (when (buffer-file-name)
    (save-excursion
      (buffer-substring-no-properties (point-min) (point)))))


(defun get-diff (lines s)
  "Return the lines that is not in string s."
  (if (null lines)
      '()
    (let ((l (car lines)))
      (if (string-match (regexp-quote l) s)
	  (get-diff (cdr lines) s)
	lines))))


(defun get-lcs-length (str1 str2)
  "Get the length of the longest common substring."
  (let* ((len1 (length str1))
	 (len2 (length str2))
	 (pre (make-vector (1+ len2) 0))
	 (cur (make-vector (1+ len2) 0))
	 (max-len 0))
    (dotimes (i len1)
      (dotimes (j len2)
	(if (equal (aref str1 i) (aref str2 j))
	    (progn
	      (aset cur (1+ j) (1+ (aref pre j)))
	      (setq max-len (max max-len
				 (aref cur (1+ j)))))
	  (aset cur (1+ j) 0)))
      (setq pre (copy-sequence cur))
      (setq cur (make-vector (1+ len2) 0)))
    max-len))


(defun filter-lines (lines filtered)
  "Filter the Markdown code block delimiters from lines."
  (if (null lines)
      (reverse filtered)
    (let* ((line (car lines))
	   (pattern
	    "```[a-zA-Z]*\n?\\|‘‘‘[a-zA-Z]*\n?")
	   (line-filtered
	    (replace-regexp-in-string pattern "" line)))
      (when (> (length line-filtered) 0)
	(setq filtered (cons line-filtered filtered)))
      (filter-lines (cdr lines) filtered))))


(defun call-api (message callback)
  "Use the request package to request the API."
  (request
    orion-api-url
    :type "POST"
    :headers `(("Authorization" . ,(concat
				    "Bearer "
				    orion-api-key))
	       ("Content-Type" . "application/json"))
    :data (json-encode
	   `((model . ,orion-model)
	     (messages . [((role . "user")
			   (content . ,message))])))
    :parser 'json-read
    :success (cl-function
	      (lambda (&key data &allow-other-keys)
		(funcall callback data)))
    :error (cl-function
	    (lambda (&key error-thrown &allow-other-keys)
	      (message "API request error: %s"
		       error-thrown)))))


(defun api-code-suggestion ()
  "Request API to obtain code suggestion."
  (let ((code-snippet (take-code-snippet))
	(line-content (get-line-content)))
    (when (> (length code-snippet) 0)
      (let ((msg
	     (format
	      "%s\n%s\n%s\n%s\n%s"
	      "Please complete this line of code: "
	      line-content
	      "Based on the following content: "
	      code-snippet
	      (concat
	       "Please only provide the code that needs "
	       "to be completed."
	       "Do not include any other content."))))
	(call-api
	 msg
	 (lambda (response)
	   (let* ((suggestion
		   (alist-get
		    'content
		    (alist-get
		     'message
		     (aref
		      (alist-get 'choices
				 response)
		      0))))
		  (lines
		   (filter-lines
		    (split-string suggestion "\n") '()))
		  (code-suggestion-fn
		   (lambda ()
		     (when (> (length suggestion) 0)
		       (setq code-suggestion suggestion)
		       (message
			"%s\nUse C-c TAB to accept"
			code-suggestion)))))
	     (setq suggestion
		   (string-join
		    (get-diff lines code-snippet) "\n"))
	     (setq delete-offset
		   (get-lcs-length suggestion line-content))
	     (funcall code-suggestion-fn))))))))


(defun code-completion ()
  "Replace current line with the code suggestion."
  (interactive)
  (delete-region (- (point) delete-offset) (point))
  (insert code-suggestion))
	  

(defun run-orion ()
  "Run orion with M-x run-orion RET"
  (interactive)
  (let ((pre (take-code-snippet)))
    (setq orion-timer
	  (run-with-timer
	   timer-interval
	   timer-interval
	   (lambda ()
	     (when (buffer-modified-p)
	       (save-buffer)
	       (let ((cur (take-code-snippet)))
		 (when (not (equal pre cur))
		   (api-code-suggestion)
		   (setq pre cur)))))))))


(defun stop-orion ()
  "Stop orion with M-x stop-orion RET"
  (interactive)
  (when (timerp orion-timer)
    (cancel-timer orion-timer)
    (setq orion-timer nil)))


(provide 'orion)
