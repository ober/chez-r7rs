;;; (r7rs internal promises) — R7RS lazy evaluation with iterative forcing
;;; Implements delay-force (also known as lazy) for proper tail-recursive
;;; lazy sequences without stack overflow.

(library (r7rs internal promises)
  (export make-r7rs-promise r7rs-promise?
          r7rs-promise-tag r7rs-promise-tag-set!
          r7rs-promise-value r7rs-promise-value-set!
          r7rs:make-promise r7rs:force)
  (import (chezscheme))

  ;; Promise record: tag is 'lazy, 'eager, or 'forcing
  ;; When tag='lazy,    value is a thunk
  ;; When tag='eager,   value is the forced result
  ;; When tag='forcing, value is still the thunk (re-entrant guard)
  (define-record-type r7rs-promise
    (fields (mutable tag) (mutable value))
    (nongenerative r7rs-promise-uid-v1))

  ;; make-promise: wrap non-promise values in an eager promise
  (define (r7rs:make-promise obj)
    (if (r7rs-promise? obj)
        obj
        (make-r7rs-promise 'eager obj)))

  ;; force: iteratively unwrap lazy promises (trampoline)
  (define (r7rs:force promise)
    (unless (r7rs-promise? promise)
      (error 'force "not a promise" promise))
    (let loop ((p promise))
      (case (r7rs-promise-tag p)
        ((eager)
         (r7rs-promise-value p))
        ((lazy)
         ;; Mark as forcing to detect re-entrancy
         (r7rs-promise-tag-set! p 'forcing)
         (let ((result ((r7rs-promise-value p))))
           (if (r7rs-promise? result)
               ;; delay-force case: adopt inner promise's state
               (begin
                 (r7rs-promise-tag-set! p (r7rs-promise-tag result))
                 (r7rs-promise-value-set! p (r7rs-promise-value result))
                 ;; Forward inner promise to outer (sharing)
                 (r7rs-promise-tag-set! result (r7rs-promise-tag p))
                 (r7rs-promise-value-set! result (r7rs-promise-value p))
                 (loop p))
               (begin
                 (r7rs-promise-tag-set! p 'eager)
                 (r7rs-promise-value-set! p result)
                 result))))
        ((forcing)
         (error 'force "re-entrant promise forcing"))
        (else
         (error 'force "corrupt promise state" p)))))
)
