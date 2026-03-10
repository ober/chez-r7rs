;;; tests/ports-test.ss — Tests for port procedures
(import (scheme base) (tests check))

;; String ports
(let ((p (open-output-string)))
  (write-char #\H p)
  (write-char #\i p)
  (check (get-output-string p) => "Hi"))

(let ((p (open-input-string "hello")))
  (check (read-char p) => #\h)
  (check (peek-char p) => #\e)
  (check (read-char p) => #\e)
  (check (read-char p) => #\l)
  (check (read-char p) => #\l)
  (check (read-char p) => #\o)
  (check (eof-object? (read-char p)) => #t))

;; read-line
(let ((p (open-input-string "line1\nline2\nline3")))
  (check (read-line p) => "line1")
  (check (read-line p) => "line2")
  (check (read-line p) => "line3")
  (check (eof-object? (read-line p)) => #t))

;; Bytevector ports
(let ((p (open-output-bytevector)))
  (write-u8 1 p)
  (write-u8 2 p)
  (write-u8 3 p)
  (check (get-output-bytevector p) => (bytevector 1 2 3)))

(let ((p (open-input-bytevector (bytevector 10 20 30))))
  (check (read-u8 p) => 10)
  (check (peek-u8 p) => 20)
  (check (read-u8 p) => 20)
  (check (read-u8 p) => 30)
  (check (eof-object? (read-u8 p)) => #t))

;; Port state predicates
(let ((p (open-input-string "x")))
  (check (input-port-open? p) => #t)
  (close-input-port p)
  (check (input-port-open? p) => #f))

(let ((p (open-output-string)))
  (check (output-port-open? p) => #t)
  (close-output-port p)
  (check (output-port-open? p) => #f))

;; Port type predicates
(let ((tp (open-input-string "x"))
      (bp (open-input-bytevector (bytevector 1))))
  (check (textual-port? tp) => #t)
  (check (binary-port?  tp) => #f)
  (check (textual-port? bp) => #f)
  (check (binary-port?  bp) => #t))

;; read-bytevector
(let ((p (open-input-bytevector (bytevector 1 2 3 4 5))))
  (check (read-bytevector 3 p) => (bytevector 1 2 3))
  (check (read-bytevector 2 p) => (bytevector 4 5))
  (check (eof-object? (read-bytevector 1 p)) => #t))

;; write-bytevector
(let ((p (open-output-bytevector)))
  (write-bytevector (bytevector 1 2 3 4 5) p 1 3)
  (check (get-output-bytevector p) => (bytevector 2 3)))

(test-summary)
