;;; (scheme lazy) — R7RS §6.3.3
;;; Lazy evaluation: delay, delay-force (lazy), force, make-promise, promise?

(library (scheme lazy)
  (export delay delay-force force make-promise promise?)
  (import (except (chezscheme) delay force)
          (r7rs internal promises))

  ;; delay: create a lazy promise that evaluates expr once when forced
  (define-syntax delay
    (syntax-rules ()
      ((_ expr)
       (make-r7rs-promise 'lazy (lambda () expr)))))

  ;; delay-force (also spelled "lazy" in some texts):
  ;; expr must evaluate to a promise; enables iterative forcing
  (define-syntax delay-force
    (syntax-rules ()
      ((_ expr)
       (make-r7rs-promise 'lazy (lambda () expr)))))

  ;; force: iteratively force a promise
  (define force r7rs:force)

  ;; make-promise: wrap a value in an eager promise (or return promise as-is)
  (define make-promise r7rs:make-promise)

  ;; promise?: test if an object is an R7RS promise
  (define promise? r7rs-promise?)
)
