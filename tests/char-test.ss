;;; tests/char-test.ss — Tests for (scheme char)
(import (scheme char) (tests check))

(check (char-alphabetic? #\a) => #t)
(check (char-alphabetic? #\1) => #f)
(check (char-numeric?    #\5) => #t)
(check (char-numeric?    #\a) => #f)
(check (char-whitespace? #\space) => #t)
(check (char-whitespace? #\a)     => #f)
(check (char-upper-case? #\A) => #t)
(check (char-lower-case? #\a) => #t)
(check (char-upcase #\a)      => #\A)
(check (char-downcase #\A)    => #\a)

(check (digit-value #\0) => 0)
(check (digit-value #\9) => 9)
(check (digit-value #\a) => #f)
(check (digit-value #\space) => #f)

(check (char-ci=? #\a #\A) => #t)
(check (char-ci<? #\a #\B) => #t)

(check (string-upcase   "hello") => "HELLO")
(check (string-downcase "WORLD") => "world")

(test-summary)
