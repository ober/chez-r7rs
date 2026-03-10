;;; tests/write-test.ss — Tests for (scheme write)
(import (scheme write) (scheme base) (tests check))

(define (write-to-string obj)
  (let ((p (open-output-string)))
    (write obj p)
    (get-output-string p)))

(define (display-to-string obj)
  (let ((p (open-output-string)))
    (display obj p)
    (get-output-string p)))

(check (write-to-string "hello")   => "\"hello\"")
(check (write-to-string 'foo)      => "foo")
(check (write-to-string '(1 2 3))  => "(1 2 3)")
(check (display-to-string "hello") => "hello")

(define (write-string-to-string s . args)
  (let ((p (open-output-string)))
    (apply write-string s p args)
    (get-output-string p)))

(check (write-string-to-string "hello")     => "hello")
(check (write-string-to-string "hello" 1 3) => "el")

(define (write-shared-to-string obj)
  (let ((p (open-output-string)))
    (write-shared obj p)
    (get-output-string p)))

(check (write-shared-to-string '(1 2 3)) => "(1 2 3)")

(define (write-simple-to-string obj)
  (let ((p (open-output-string)))
    (write-simple obj p)
    (get-output-string p)))

(check (write-simple-to-string '(1 2 3)) => "(1 2 3)")
(check (write-simple-to-string "hello")  => "\"hello\"")

(test-summary)
