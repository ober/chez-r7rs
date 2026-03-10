;;; (scheme process-context) — R7RS §6.14
;;; command-line, exit, emergency-exit, get-environment-variable,
;;; get-environment-variables

(library (scheme process-context)
  (export command-line exit emergency-exit
          get-environment-variable get-environment-variables)
  (import (rename (except (chezscheme) command-line)
                  (exit chez:exit)))

  ;; command-line: return list of strings (program name + arguments)
  ;; Chez's (command-line-arguments) returns a list of args without program name.
  ;; R7RS: first element is the program name (may be "" if unavailable).
  (define (command-line)
    (cons "" (command-line-arguments)))

  ;; exit: R7RS (exit [obj])
  ;; #t or omitted → success (0), #f → failure (1), integer → that code
  (define (exit . args)
    (if (null? args)
        (chez:exit 0)
        (let ((obj (car args)))
          (cond
            ((eq? obj #t)   (chez:exit 0))
            ((eq? obj #f)   (chez:exit 1))
            ((integer? obj) (chez:exit obj))
            (else           (chez:exit 0))))))

  ;; emergency-exit: immediate process exit without cleanup
  ;; Uses C's exit() directly via foreign-procedure.
  (define (emergency-exit . args)
    (let ((status (if (null? args) 0
                      (let ((obj (car args)))
                        (cond
                          ((eq? obj #t)   0)
                          ((eq? obj #f)   1)
                          ((integer? obj) obj)
                          (else           0))))))
      ((foreign-procedure "exit" (int) void) status)))

  ;; get-environment-variable: look up a single env var by name
  (define (get-environment-variable name)
    (getenv name))

  ;; get-environment-variables: return all env vars as ((name . value) ...) alist
  ;; Chez doesn't directly expose environ, so we fall back to /proc/self/environ
  ;; on Linux.  On other systems, return empty list.
  (define (get-environment-variables)
    (if (file-exists? "/proc/self/environ")
        (call-with-input-file "/proc/self/environ"
          (lambda (port)
            ;; /proc/self/environ is NUL-separated, but get-line reads until newline.
            ;; We read the whole file and split on NUL.
            (let loop ((acc '()))
              (let ((ch (read-char port)))
                (if (eof-object? ch)
                    (reverse acc)
                    ;; Read until NUL or EOF, then split on =
                    (let inner ((chars (list ch)))
                      (let ((next (read-char port)))
                        (if (or (eof-object? next) (char=? next #\nul))
                            (let* ((s (list->string (reverse chars)))
                                   (eq-pos (string-index s #\=)))
                              (if eq-pos
                                  (loop (cons (cons (substring s 0 eq-pos)
                                                    (substring s (+ eq-pos 1)
                                                               (string-length s)))
                                              acc))
                                  (loop acc)))
                            (inner (cons next chars))))))))))
        '()))

  ;; Helper: find character in string, return index or #f
  (define (string-index s ch)
    (let ((len (string-length s)))
      (let loop ((i 0))
        (cond ((= i len) #f)
              ((char=? (string-ref s i) ch) i)
              (else (loop (+ i 1)))))))
)
