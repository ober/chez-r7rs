;;; (r7rs internal error-objects) — R7RS error object bridge
;;; Maps R7RS error semantics onto Chez condition objects.

(library (r7rs internal error-objects)
  (export r7rs:error error-object? error-object-message
          error-object-irritants read-error? file-error?)
  (import (chezscheme))

  ;; R7RS error: (error message irritant ...)
  ;; Chez error: (error who message irritant ...)
  ;; We create a condition with who='r7rs so it's still a standard Chez condition.
  (define (r7rs:error message . irritants)
    (unless (string? message)
      (raise
        (condition
          (make-error)
          (make-who-condition 'error)
          (make-message-condition "error: message must be a string")
          (make-irritants-condition (list message)))))
    (raise
      (condition
        (make-error)
        (make-who-condition 'r7rs)
        (make-message-condition message)
        (make-irritants-condition irritants))))

  ;; error-object? — true for any error condition
  (define (error-object? obj)
    (and (condition? obj)
         (error? obj)))

  ;; error-object-message — extract message string
  (define (error-object-message obj)
    (if (message-condition? obj)
        (condition-message obj)
        ""))

  ;; error-object-irritants — extract irritant list
  (define (error-object-irritants obj)
    (if (irritants-condition? obj)
        (condition-irritants obj)
        '()))

  ;; read-error? — maps to Chez lexical violation
  (define (read-error? obj)
    (and (condition? obj)
         (lexical-violation? obj)))

  ;; file-error? — maps to Chez i/o error
  (define (file-error? obj)
    (and (condition? obj)
         (i/o-error? obj)))
)
