;;;; Minimal implementation of the source-location tracking machinery, which
;;;; defers the real work to until source-location.lisp

;;;; This software is part of the SBCL system. See the README file for
;;;; more information.
;;;;
;;;; This software is derived from the CMU CL system, which was
;;;; written at Carnegie Mellon University and released into the
;;;; public domain. The software is in the public domain and is
;;;; provided with absolutely no warranty. See the COPYING and CREDITS
;;;; files for more information.

(in-package "SB!C")

(defvar *source-location-thunks* nil)

;; Should get called only in unusual circumstances. Normally handled
;; by a compiler macro.
(defun source-location ()
  nil)

;; Will be redefined in src/code/source-location.lisp
#-sb-xc-host
(define-compiler-macro source-location ()
  (when (and (boundp '*source-info*)
             (symbol-value '*source-info*))
    `(cons ,(make-file-info-namestring
              *compile-file-pathname*
              (source-info-file-info (symbol-value '*source-info*)))
           ,(when (boundp '*current-path*)
                  (source-path-tlf-number (symbol-value '*current-path*))))))

;; If the whole source location tracking machinery has been loaded
;; (detected by the type of SOURCE-LOCATION), execute BODY. Otherwise
;; wrap it in a lambda and execute later.
(defmacro with-source-location ((source-location) &body body)
  `(when ,source-location
     (if (consp ,source-location)
         (push (lambda ()
                 (let ((,source-location
                        (make-definition-source-location
                         :namestring (car ,source-location)
                         :toplevel-form-number (cdr ,source-location))))
                   ,@body))
               *source-location-thunks*)
         ,@body)))