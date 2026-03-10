;;; (r7rs internal division) — Floor and truncate division
;;; R7RS adds floor/ floor-quotient floor-remainder
;;; and truncate/ truncate-quotient truncate-remainder.
;;; Note: Chez already has quotient/remainder (truncate semantics)
;;; and modulo (floor semantics for positive divisor).

(library (r7rs internal division)
  (export floor/ floor-quotient floor-remainder
          truncate/ truncate-quotient truncate-remainder)
  (import (chezscheme))

  ;; --- Floor division ---
  ;; floor-quotient: largest integer q such that q*d <= n
  (define (floor-quotient n d)
    (exact (floor (/ n d))))

  ;; floor-remainder: n - d * floor-quotient(n, d)
  (define (floor-remainder n d)
    (- n (* d (floor-quotient n d))))

  ;; floor/: return both quotient and remainder as multiple values
  (define (floor/ n d)
    (let ((fq (floor-quotient n d)))
      (values fq (- n (* d fq)))))

  ;; --- Truncate division ---
  ;; truncate-quotient: truncate toward zero (same as Chez quotient)
  (define (truncate-quotient n d)
    (quotient n d))

  ;; truncate-remainder: n - d * truncate-quotient(n, d) (same as Chez remainder)
  (define (truncate-remainder n d)
    (remainder n d))

  ;; truncate/: return both as multiple values
  (define (truncate/ n d)
    (values (truncate-quotient n d)
            (truncate-remainder n d)))
)
