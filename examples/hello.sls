;;; examples/hello.sls — Basic R7RS program example
;;;
;;; Run with:
;;;   scheme --libdirs lib --program examples/hello.sls

(import (scheme base)
        (scheme write)
        (scheme process-context))

;; Display a greeting
(display "Hello, R7RS world!")
(newline)

;; Show available features
(display "Features: ")
(write (features))
(newline)

;; Demonstrate basic R7RS features

;; define-record-type (SRFI-9)
(define-record-type <person>
  (make-person name age)
  person?
  (name person-name)
  (age  person-age person-set-age!))

(let ((p (make-person "Alice" 30)))
  (display (string-append "Name: " (person-name p)))
  (newline)
  (display "Age: ")
  (display (person-age p))
  (newline)
  (person-set-age! p 31)
  (display "Next year: ")
  (display (person-age p))
  (newline))

;; floor/ and truncate/
(define-values (q r) (floor/ 17 5))
(display (string-append "17 floor/ 5 = " (number->string q) " rem " (number->string r)))
(newline)

;; Lazy evaluation
(define lazy-val
  (delay (begin
           (display "computing...")
           (newline)
           42)))

(display "Before force")
(newline)
(display (force lazy-val))
(newline)
(display (force lazy-val))  ;; Not recomputed
(newline)

;; String operations
(display (string-map char-upcase "hello world"))
(newline)

(exit 0)
