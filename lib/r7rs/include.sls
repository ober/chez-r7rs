;;; (r7rs include) — include and include-ci macros
;;; For use outside of define-library contexts.

(library (r7rs include)
  (export include include-ci)
  (import (chezscheme))

  (define-syntax include
    (lambda (x)
      (define (read-file filename)
        (with-input-from-file filename
          (lambda ()
            (let loop ((forms '()))
              (let ((form (read)))
                (if (eof-object? form)
                    (reverse forms)
                    (loop (cons form forms))))))))
      (syntax-case x ()
        ((_ filename ...)
         (let ((forms (apply append
                             (map (lambda (fn)
                                    (read-file (syntax->datum fn)))
                                  (syntax->list #'(filename ...))))))
           (datum->syntax x `(begin ,@forms)))))))

  (define-syntax include-ci
    (lambda (x)
      (define (read-file-ci filename)
        (with-input-from-file filename
          (lambda ()
            (parameterize ((case-sensitive #f))
              (let loop ((forms '()))
                (let ((form (read)))
                  (if (eof-object? form)
                      (reverse forms)
                      (loop (cons form forms)))))))))
      (syntax-case x ()
        ((_ filename ...)
         (let ((forms (apply append
                             (map (lambda (fn)
                                    (read-file-ci (syntax->datum fn)))
                                  (syntax->list #'(filename ...))))))
           (datum->syntax x `(begin ,@forms)))))))
)
