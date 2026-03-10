;;; tests/check.sls — Test checking infrastructure
;;; Provides check macro and test summary for standalone test programs.

(library (tests check)
  (export check test-summary =>)
  (import (chezscheme))

  (define total  0)
  (define passed 0)
  (define failed 0)

  (define (check-equal expr-str expected got)
    (set! total (+ total 1))
    (if (equal? got expected)
        (begin
          (set! passed (+ passed 1))
          (display "."))
        (begin
          (set! failed (+ failed 1))
          (printf "~nFAIL: ~a~n  expected: ~s~n  got:      ~s~n"
                  expr-str expected got))))

  (define-syntax check
    (syntax-rules (=>)
      ((_ expr => expected)
       (check-equal (format "~s" 'expr) expected expr))))

  (define (test-summary)
    (newline)
    (printf "~a / ~a tests passed~n" passed total)
    (when (> failed 0)
      (printf "~a tests FAILED~n" failed)
      (exit 1)))
)
