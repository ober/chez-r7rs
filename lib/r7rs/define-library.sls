;;; (r7rs define-library) — define-library macro
;;; Transforms R7RS define-library syntax into R6RS library forms.
;;;
;;; R7RS define-library syntax:
;;;   (define-library <library-name>
;;;     <library-declaration> ...)
;;;
;;; where <library-declaration> is one of:
;;;   (export <export-spec> ...)
;;;   (import <import-set> ...)
;;;   (begin <command-or-definition> ...)
;;;   (include <filename> ...)
;;;   (include-ci <filename> ...)
;;;   (include-library-declarations <filename> ...)
;;;   (cond-expand <clause> ...)

(library (r7rs define-library)
  (export define-library)
  (import (chezscheme)
          (r7rs features))

  (define-syntax define-library
    (lambda (stx)
      (define (collect-declarations decls exports imports bodies)
        ;; Process each declaration and accumulate exports, imports, body forms
        (if (null? decls)
            (values (reverse exports) (reverse imports) (reverse bodies))
            (let ((decl (car decls))
                  (rest (cdr decls)))
              (syntax-case decl (export import begin
                                 include include-ci
                                 include-library-declarations
                                 cond-expand)
                ((export spec ...)
                 (collect-declarations rest
                   (append (reverse (syntax->list #'(spec ...))) exports)
                   imports bodies))
                ((import iset ...)
                 (collect-declarations rest exports
                   (append (reverse (syntax->list #'(iset ...))) imports)
                   bodies))
                ((begin form ...)
                 (collect-declarations rest exports imports
                   (append (reverse (syntax->list #'(form ...))) bodies)))
                ((include filename ...)
                 (let ((forms (apply append
                                     (map (lambda (fn)
                                            (read-forms-from-file
                                              (syntax->datum fn) #f))
                                          (syntax->list #'(filename ...))))))
                   (collect-declarations rest exports imports
                     (append (reverse (map (lambda (f)
                                             (datum->syntax decl f))
                                           forms))
                             bodies))))
                ((include-ci filename ...)
                 (let ((forms (apply append
                                     (map (lambda (fn)
                                            (read-forms-from-file
                                              (syntax->datum fn) #t))
                                          (syntax->list #'(filename ...))))))
                   (collect-declarations rest exports imports
                     (append (reverse (map (lambda (f)
                                             (datum->syntax decl f))
                                           forms))
                             bodies))))
                ((include-library-declarations filename ...)
                 ;; These are declaration forms (export/import/begin) to include
                 (let ((included-decls
                         (apply append
                                (map (lambda (fn)
                                       (map (lambda (f) (datum->syntax decl f))
                                            (read-forms-from-file
                                              (syntax->datum fn) #f)))
                                     (syntax->list #'(filename ...))))))
                   (collect-declarations
                     (append included-decls rest)
                     exports imports bodies)))
                ((cond-expand clause ...)
                 ;; Expand cond-expand at macro-expansion time
                 (let ((expanded (expand-cond-expand (syntax->list #'(clause ...)))))
                   (collect-declarations
                     (if expanded
                         (append (syntax->list expanded) rest)
                         rest)
                     exports imports bodies)))
                (_
                 ;; Unknown declaration: treat as body form
                 (collect-declarations rest exports imports
                   (cons decl bodies)))))))

      (define (read-forms-from-file filename case-fold?)
        (with-input-from-file filename
          (lambda ()
            (parameterize ((case-sensitive (not case-fold?)))
              (let loop ((forms '()))
                (let ((form (read)))
                  (if (eof-object? form)
                      (reverse forms)
                      (loop (cons form forms)))))))))

      (define (expand-cond-expand clauses)
        ;; Returns a list of declarations if a clause matches, else #f for no-match
        (cond
          ((null? clauses) #f)
          (else
           (let ((clause (car clauses)))
             (syntax-case clause (else)
               ((else decl ...)
                #'(decl ...))
               ((req decl ...)
                (if (feature-satisfied? (syntax->datum #'req))
                    #'(decl ...)
                    (expand-cond-expand (cdr clauses)))))))))

      (define (feature-satisfied? req)
        (cond
          ((symbol? req)
           (if (eq? req 'else) #t (memq req r7rs-features)))
          ((pair? req)
           (case (car req)
             ((and) (let loop ((rs (cdr req)))
                      (or (null? rs) (and (feature-satisfied? (car rs))
                                          (loop (cdr rs))))))
             ((or)  (let loop ((rs (cdr req)))
                      (and (not (null? rs))
                           (or (feature-satisfied? (car rs)) (loop (cdr rs))))))
             ((not) (not (feature-satisfied? (cadr req))))
             ((library) #t) ;; optimistic
             (else #f)))
          (else #f)))

      (syntax-case stx ()
        ((kw lib-name decl ...)
         (let-values (((exports imports bodies)
                       (collect-declarations
                         (syntax->list #'(decl ...))
                         '() '() '())))
           (with-syntax
             ((export-clause  (datum->syntax #'kw exports))
              (import-clause  (datum->syntax #'kw imports))
              (body-forms     (datum->syntax #'kw bodies)))
             #'(library lib-name
                 (export . export-clause)
                 (import . import-clause)
                 . body-forms)))))))
)
