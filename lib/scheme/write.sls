;;; (scheme write) — R7RS §6.13.3
;;; Output procedures: write, display, newline, write-char, write-string,
;;; write-shared, write-simple.

(library (scheme write)
  (export write display newline write-char write-string
          write-shared write-simple)
  (import (chezscheme)
          (r7rs internal write))

  ;; write, display, newline, write-char are re-exported from (chezscheme).
  ;; They already accept an optional port argument.

  ;; write-string: R7RS writes a string (or substring) to a port
  (define (write-string s . args)
    (let* ((port  (if (null? args) (current-output-port) (car args)))
           (args2 (if (null? args) '() (cdr args)))
           (start (if (null? args2) 0 (car args2)))
           (args3 (if (null? args2) '() (cdr args2)))
           (end   (if (null? args3) (string-length s) (car args3))))
      (if (and (= start 0) (= end (string-length s)))
          (display s port)
          (display (substring s start end) port))))

  ;; write-shared, write-simple come from (r7rs internal write)
)
