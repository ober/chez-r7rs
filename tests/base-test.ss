;;; tests/base-test.ss — Tests for (scheme base)
;;; Run as: scheme --libdirs lib --program tests/base-test.ss

(import (scheme base)
        (tests check))

;; --- Numeric predicates ---
(check (exact-integer? 42)    => #t)
(check (exact-integer? 42.0)  => #f)
(check (exact-integer? 1/2)   => #f)
(check (exact-integer? -5)    => #t)

;; --- square ---
(check (square 5)    => 25)
(check (square -3)   => 9)
(check (square 0)    => 0)
(check (square 1/2)  => 1/4)

;; --- exact-integer-sqrt ---
(check (call-with-values (lambda () (exact-integer-sqrt 14)) list) => '(3 5))
(check (call-with-values (lambda () (exact-integer-sqrt 0))  list) => '(0 0))
(check (call-with-values (lambda () (exact-integer-sqrt 9))  list) => '(3 0))
(check (call-with-values (lambda () (exact-integer-sqrt 25)) list) => '(5 0))

;; --- boolean=? ---
(check (boolean=? #t #t)         => #t)
(check (boolean=? #f #f)         => #t)
(check (boolean=? #t #f)         => #f)
(check (boolean=? #t #t #t)      => #t)
(check (boolean=? #t #t #f)      => #f)

;; --- symbol=? ---
(check (symbol=? 'foo 'foo)      => #t)
(check (symbol=? 'foo 'bar)      => #f)
(check (symbol=? 'a 'a 'a)       => #t)
(check (symbol=? 'a 'a 'b)       => #f)

;; --- make-list ---
(check (make-list 3)        => '(#f #f #f))
(check (make-list 3 'x)     => '(x x x))
(check (make-list 0)        => '())

;; --- list-copy ---
(let ((orig '(1 2 3)))
  (let ((copy (list-copy orig)))
    (check (equal? copy '(1 2 3)) => #t)
    (check (eq? copy orig) => #f)))

;; --- list-set! ---
(let ((lst (list 'a 'b 'c)))
  (list-set! lst 1 'x)
  (check lst => '(a x c)))

;; --- assoc with comparator ---
(check (assoc 2.0 '((1 a) (2 b) (3 c)) =) => '(2 b))
(check (assoc "b" '(("a" 1) ("b" 2)) string=?) => '("b" 2))

;; --- member with comparator ---
(check (member 2.0 '(1 2 3) =) => '(2 3))
(check (member "b" '("a" "b" "c") string=?) => '("b" "c"))

;; --- string-map ---
(check (string-map char-upcase "hello") => "HELLO")
(check (string-map (lambda (c) (integer->char (+ 1 (char->integer c)))) "abc") => "bcd")

;; --- string-for-each ---
(let ((result '()))
  (string-for-each (lambda (c) (set! result (cons c result))) "abc")
  (check result => '(#\c #\b #\a)))

;; --- vector-copy ---
(check (vector-copy '#(1 2 3 4 5))      => '#(1 2 3 4 5))
(check (vector-copy '#(1 2 3 4 5) 2)    => '#(3 4 5))
(check (vector-copy '#(1 2 3 4 5) 1 3)  => '#(2 3))

;; --- vector-copy! ---
(let ((v (vector 1 2 3 4 5)))
  (vector-copy! v 1 '#(10 20) 0 2)
  (check v => '#(1 10 20 4 5)))

;; --- vector-append ---
(check (vector-append '#(1 2) '#(3 4) '#(5)) => '#(1 2 3 4 5))

;; --- bytevector operations ---
(check (bytevector-length (make-bytevector 5)) => 5)
(let ((bv (bytevector 1 2 3 4 5)))
  (check (bytevector-length bv) => 5)
  (check (bytevector-u8-ref bv 2) => 3)
  (bytevector-u8-set! bv 2 99)
  (check (bytevector-u8-ref bv 2) => 99))

;; --- bytevector-copy with range ---
(check (bytevector-copy (bytevector 1 2 3 4 5) 1 3) => (bytevector 2 3))
(check (bytevector-copy (bytevector 1 2 3) 1)        => (bytevector 2 3))

;; --- bytevector-copy! (R7RS arg order: to at from [start [end]]) ---
(let ((dst (make-bytevector 5 0))
      (src (bytevector 10 20 30)))
  (bytevector-copy! dst 1 src)
  (check dst => (bytevector 0 10 20 30 0)))

(let ((dst (make-bytevector 5 0))
      (src (bytevector 10 20 30)))
  (bytevector-copy! dst 2 src 1 3)
  (check dst => (bytevector 0 0 20 30 0)))

;; --- bytevector-append ---
(check (bytevector-append (bytevector 1 2) (bytevector 3 4)) => (bytevector 1 2 3 4))

;; --- string-copy with range ---
(check (string-copy "hello" 1 3) => "el")
(check (string-copy "hello" 2)   => "llo")

;; --- string-copy! ---
(let ((s (string-copy "hello")))
  (string-copy! s 1 "xyz" 0 2)
  (check s => "hxylo"))

;; --- define-values ---
(define-values (a b c) (values 1 2 3))
(check a => 1)
(check b => 2)
(check c => 3)

;; --- features ---
(check (list? (features)) => #t)
(check (and (memq 'r7rs (features)) #t) => #t)

;; --- floor/ truncate/ ---
(check (call-with-values (lambda () (floor/ 5 2))    list) => '(2 1))
(check (call-with-values (lambda () (floor/ -5 2))   list) => '(-3 1))
(check (call-with-values (lambda () (truncate/ 5 2)) list) => '(2 1))
(check (call-with-values (lambda () (truncate/ -5 2)) list) => '(-2 -1))

;; --- floor-quotient / floor-remainder ---
(check (floor-quotient  5  2) => 2)
(check (floor-quotient -5  2) => -3)
(check (floor-quotient  5 -2) => -3)
(check (floor-remainder 5  2) => 1)
(check (floor-remainder -5 2) => 1)

;; --- truncate-quotient / truncate-remainder ---
(check (truncate-quotient  5  2) => 2)
(check (truncate-quotient -5  2) => -2)
(check (truncate-remainder 5  2) => 1)
(check (truncate-remainder -5 2) => -1)

;; --- promises ---
(let ((p (delay 1)))
  (check (promise? p) => #t)
  (check (force p)    => 1)
  (check (force p)    => 1))

;; --- delay-force (iterative) ---
(define (stream-iota n)
  (let loop ((i 0) (acc '()))
    (if (= i n)
        (delay acc)
        (delay-force (loop (+ i 1) (cons i acc))))))
(check (length (force (stream-iota 100))) => 100)

;; --- make-promise ---
(check (force (make-promise 42)) => 42)
(let ((p (delay 1)))
  (check (eq? (make-promise p) p) => #t))

;; --- error-object? ---
(let ((e (call-with-current-continuation
           (lambda (k)
             (with-exception-handler k (lambda () (error "test" 1 2)))))))
  (check (error-object? e) => #t)
  (check (error-object-message e) => "test")
  (check (error-object-irritants e) => '(1 2)))

(test-summary)
