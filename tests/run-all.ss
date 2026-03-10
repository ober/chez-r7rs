;;; tests/run-all.ss — Test runner for chez-r7rs
;;; Runs each test file as a subprocess and reports results.

(import (chezscheme))

(library-directories (cons "lib" (library-directories)))

(define (run-test-file file)
  (printf "~n=== ~a ===~n" file)
  (let ((result
         (system (format "scheme --libdirs lib:. --program ~a 2>&1" file))))
    (if (= result 0)
        (printf "PASSED~n")
        (printf "FAILED (exit ~a)~n" result))
    (= result 0)))

(define test-files
  '("tests/base-test.ss"
    "tests/char-test.ss"
    "tests/lazy-test.ss"
    "tests/write-test.ss"
    "tests/record-type-test.ss"
    "tests/division-test.ss"
    "tests/ports-test.ss"
    "tests/define-library-test.ss"))

(define passed 0)
(define failed 0)

(for-each
  (lambda (f)
    (if (run-test-file f)
        (set! passed (+ passed 1))
        (set! failed (+ failed 1))))
  test-files)

(printf "~n=== Summary ===~n")
(printf "Passed: ~a / ~a~n" passed (length test-files))

(when (> failed 0)
  (exit 1))
