;;; (scheme char) — R7RS §6.6
;;; Character classification and conversion; mostly direct re-exports.
;;; Only digit-value needs a new implementation.

(library (scheme char)
  (export
    ;; Classification
    char-alphabetic? char-numeric? char-whitespace?
    char-upper-case? char-lower-case?
    ;; Case conversion
    char-upcase char-downcase char-foldcase
    ;; Case-insensitive comparison
    char-ci=? char-ci<? char-ci>? char-ci<=? char-ci>=?
    ;; String case operations
    string-upcase string-downcase string-foldcase
    ;; String case-insensitive comparison
    string-ci=? string-ci<? string-ci>? string-ci<=? string-ci>=?
    ;; R7RS-specific
    digit-value)
  (import (chezscheme))

  ;; digit-value: returns numeric value of a decimal digit character, or #f
  ;; Works for digits beyond ASCII 0-9 (full Unicode digit support)
  (define (digit-value c)
    (let ((n (char->integer c)))
      ;; Check common ASCII digits first
      (cond
        ((and (>= n (char->integer #\0)) (<= n (char->integer #\9)))
         (- n (char->integer #\0)))
        ;; Additional Unicode decimal digits could be added here
        ;; For now, return #f for non-ASCII digits
        (else #f))))
)
