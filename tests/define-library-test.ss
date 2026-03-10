;;; tests/define-library-test.ss — Tests for cond-expand and r7rs features
;;; Note: define-library macro is tested via the library files themselves.
;;; In --program mode, inline library definitions via macros cannot be imported,
;;; so we test cond-expand which can be tested inline.

(import (except (scheme base) cond-expand)
        (r7rs cond-expand)
        (r7rs features)
        (tests check))

;; --- cond-expand tests ---

(define result
  (cond-expand
    (r7rs "is-r7rs")
    (else "not-r7rs")))
(check result => "is-r7rs")

(define result2
  (cond-expand
    ((and r7rs chez-scheme) "both")
    (else "neither")))
(check result2 => "both")

(define result3
  (cond-expand
    ((not r7rs) "not r7rs")
    (else "is r7rs")))
(check result3 => "is r7rs")

(define result4
  (cond-expand
    ((or r7rs some-other) "has r7rs or other")
    (else "neither")))
(check result4 => "has r7rs or other")

(define result5
  (cond-expand
    (some-nonexistent-feature "bad")
    (else "good")))
(check result5 => "good")

;; r7rs-features list is non-empty
(check (pair? r7rs-features) => #t)
(check (memq 'r7rs r7rs-features) => r7rs-features)

(test-summary)
