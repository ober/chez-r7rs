;;; tests/division-test.ss — Tests for floor/ and truncate/ division
(import (scheme base) (tests check))

(check (floor-quotient  7  2) =>  3)
(check (floor-quotient -7  2) => -4)
(check (floor-quotient  7 -2) => -4)
(check (floor-quotient -7 -2) =>  3)

(check (floor-remainder  7  2) =>  1)
(check (floor-remainder -7  2) =>  1)
(check (floor-remainder  7 -2) => -1)
(check (floor-remainder -7 -2) => -1)

(check (call-with-values (lambda () (floor/  7  2)) cons) => '(3  . 1))
(check (call-with-values (lambda () (floor/ -7  2)) cons) => '(-4 . 1))

(check (truncate-quotient  7  2) =>  3)
(check (truncate-quotient -7  2) => -3)
(check (truncate-quotient  7 -2) => -3)
(check (truncate-quotient -7 -2) =>  3)

(check (truncate-remainder  7  2) =>  1)
(check (truncate-remainder -7  2) => -1)
(check (truncate-remainder  7 -2) =>  1)
(check (truncate-remainder -7 -2) => -1)

;; Relationship: q*d + r = n
(let ((check-divmod
       (lambda (n d)
         (let ((fq (floor-quotient n d))
               (fr (floor-remainder n d))
               (tq (truncate-quotient n d))
               (tr (truncate-remainder n d)))
           (check (= (+ (* fq d) fr) n) => #t)
           (check (= (+ (* tq d) tr) n) => #t)))))
  (for-each check-divmod '(7 -7 7 -7 13 -13) '(2 2 -2 -2 3 5)))

(test-summary)
