;;; tests/lazy-test.ss — Tests for (scheme lazy)
(import (except (scheme base) delay delay-force force make-promise promise?)
        (scheme lazy)
        (tests check))

(check (force (delay 1)) => 1)
(check (force (delay (+ 1 2))) => 3)

;; Memoization
(let ((count 0))
  (let ((p (delay (begin (set! count (+ count 1)) count))))
    (check (force p) => 1)
    (check (force p) => 1)
    (check count     => 1)))

(check (promise? (delay 1)) => #t)
(check (promise? 42)        => #f)

(check (force (make-promise 99)) => 99)
(let ((p (delay 1)))
  (check (eq? (make-promise p) p) => #t))

;; delay-force: iterative (should not overflow stack)
(define (count-down n)
  (if (= n 0)
      (delay 'done)
      (delay-force (count-down (- n 1)))))

(check (force (count-down 10000)) => 'done)

(test-summary)
