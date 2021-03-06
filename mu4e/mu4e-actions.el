;;; mu4e-actions.el -- part of mu4e, the mu mail user agent
;;
;; Copyright (C) 2011-2012 Dirk-Jan C. Binnema

;; Author: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Maintainer: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>

;; This file is not part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Example actions for messages, attachments (see chapter 'Actions' in the
;; manual)

;;; Code:
(eval-when-compile (byte-compile-disable-warning 'cl-functions))
(require 'cl)

(require 'mu4e-utils)
(require 'mu4e-meta)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mu4e-action-count-lines (msg)
  "Count the number of lines in the e-mail message. Works for
headers view and message-view."
  (message "Number of lines: %s"
    (shell-command-to-string
      (concat "wc -l < " (shell-quote-argument (plist-get msg :path))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar mu4e-msg2pdf (concat mu4e-builddir "/toys/msg2pdf/msg2pdf")
  "Path to the msg2pdf toy.")

(defun mu4e-action-view-as-pdf (msg)
  "Convert the message to pdf, then show it. Works for the message
view."
  (unless (file-executable-p mu4e-msg2pdf)
    (mu4e-error "msg2pdf not found; please set `mu4e-msg2pdf'"))
  (let* ((pdf
	  (shell-command-to-string
	    (concat mu4e-msg2pdf " "
	      (shell-quote-argument (mu4e-msg-field msg :path))
	      " 2> /dev/null")))
	 (pdf (and pdf (> (length pdf) 5)
		(substring pdf 0 -1)))) ;; chop \n
    (unless (and pdf (file-exists-p pdf))
      (message "==> %S %S" pdf (mu4e-msg-field msg :path))
      (mu4e-error "Failed to create PDF file"))
    (find-file pdf)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun mu4e-action-view-in-browser (msg)
  "View the body of the message in a web browser. You can influence
the browser to use with the variable `browse-url-generic-program'."
  (let ((html (mu4e-msg-field msg :body-html))
	 (tmpfile (format "%s/%d.html" temporary-file-directory (random))))
    (unless html (mu4e-error "No html part for this message"))
       (with-temp-file tmpfile
	 (insert html)
	 (save-buffer)
	 (url-view-url (concat "file:///" tmpfile)))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defconst mu4e-text2speech-command "festival --tts"
  "Program that speaks out text it receives on standard-input.")

(defun mu4e-action-message-to-speech (msg)
  "Pronounce the message text using `mu4e-text2speech-command'."
  (unless (mu4e-msg-field msg :body-txt)
    (mu4e-error "No text body for this message"))
  (with-temp-buffer
    (insert (mu4e-msg-field msg :body-txt))
    (shell-command-on-region (point-min) (point-max)
      mu4e-text2speech-command)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar mu4e-captured-message nil
  "The last-captured message (the s-expression).")

(defun mu4e-action-capture-message (msg)
  "Remember MSG; we can create a an attachment based on this msg
with `mu4e-compose-attach-captured-message'."
  (interactive)
  (setq mu4e-captured-message msg)
  (message "Message has been captured"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defvar mu4e-org-contacts-file nil
  "File to store contact information for org-contacts. Needed by
  `mu4e-action-add-org-contact'.")

(eval-when-compile ;; silence compiler warning about free variable
  (unless (require 'org-capture nil 'noerror)
    (defvar org-capture-templates nil)))

(defun mu4e-action-add-org-contact (msg)
  "Add an org-contact entry based on the From: address of the
current message (in headers or view). You need to set
`mu4e-org-contacts-file' to the full path to the file where you
store your org-contacts."
  (unless (require 'org-capture nil 'nomu4e-error)
    (mu4e-error "org-capture is not available."))
  (unless mu4e-org-contacts-file
    (mu4e-error "`mu4e-org-contacts-file' is not defined."))
  (let* ((sender (car-safe (mu4e-msg-field msg :from)))
	  (name (car-safe sender)) (email (cdr-safe sender))
	  (blurb
	    (format
	      (concat
		"* %s%%?\n"
		":PROPERTIES:\n"
		":EMAIL:%s\n"
		":NICK:\n"
		":BIRTHDAY:\n"
		":END:\n\n")
	      (or name email "")
	      (or email "")))
	  (key "mu4e-add-org-contact-key")
	  (org-capture-templates
	    (append org-capture-templates
	      (list (list key "contacts" 'entry
		      (list 'file mu4e-org-contacts-file) blurb)))))
    (message "%S" org-capture-templates)
    (when (fboundp 'org-capture)
      (org-capture nil key))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



(provide 'mu4e-actions)
