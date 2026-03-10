;;; tests/record-type-test.ss — Tests for SRFI-9 define-record-type
(import (scheme base) (tests check))

(define-record-type <point>
  (make-point x y)
  point?
  (x point-x)
  (y point-y))

(check (point? (make-point 3 4)) => #t)
(check (point? '(3 4))           => #f)
(check (point-x (make-point 3 4)) => 3)
(check (point-y (make-point 3 4)) => 4)

;; Mutable fields
(define-record-type <counter>
  (make-counter value)
  counter?
  (value counter-value counter-set-value!))

(let ((c (make-counter 0)))
  (check (counter-value c) => 0)
  (counter-set-value! c 42)
  (check (counter-value c) => 42))

;; Field not in constructor
(define-record-type <tagged>
  (make-tagged value)
  tagged?
  (value  tagged-value)
  (label  tagged-label  tagged-set-label!))

(let ((t (make-tagged 10)))
  (check (tagged-value t) => 10)
  (check (tagged-label t) => #f)
  (tagged-set-label! t "hello")
  (check (tagged-label t) => "hello"))

;; Nested records
(define-record-type <rect>
  (make-rect tl br)
  rect?
  (tl rect-tl)
  (br rect-br))

(let* ((p1 (make-point 0 0))
       (p2 (make-point 10 20))
       (r  (make-rect p1 p2)))
  (check (point-x (rect-tl r)) => 0)
  (check (point-y (rect-br r)) => 20))

(test-summary)
