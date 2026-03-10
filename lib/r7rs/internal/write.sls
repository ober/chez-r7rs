;;; (r7rs internal write) — R7RS write variants
;;; write-shared: write with datum labels for shared/cyclic structure
;;; write-simple: write without datum labels (no cycle detection)
;;; display is already in (chezscheme)

(library (r7rs internal write)
  (export write-shared write-simple r7rs:display r7rs:write r7rs:newline)
  (import (chezscheme))

  ;; write-shared: enable Chez's graph notation for shared/cyclic structure
  (define (write-shared obj . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (parameterize ((print-graph #t))
        (write obj port))))

  ;; write-simple: disable cycle detection entirely
  (define (write-simple obj . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (parameterize ((print-graph #f))
        (write obj port))))

  ;; R7RS write: write with shared detection disabled by default
  ;; (same as Chez write but optional port arg)
  (define (r7rs:write obj . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (write obj port)))

  ;; R7RS display: optional port arg
  (define (r7rs:display obj . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (display obj port)))

  ;; R7RS newline: optional port arg
  (define (r7rs:newline . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (newline port)))
)
