;;; (r7rs internal record-type) — SRFI-9 style define-record-type
;;; Translates SRFI-9/R7RS record syntax to Chez's procedural record API.

(library (r7rs internal record-type)
  (export r7rs:define-record-type)
  (import (chezscheme))

  (define-syntax r7rs:define-record-type
    (lambda (stx)

      ;; Helper (called at expand time): for each field tag, find its syntax
      ;; object from the constructor parameters, or return #'#f if not present.
      (define (build-new-args all-tags ctor-tags ctor-stxs)
        (map (lambda (tag)
               (let find ((ct ctor-tags) (cs ctor-stxs))
                 (cond ((null? ct)            #'#f)
                       ((eq? tag (car ct))    (car cs))
                       (else                  (find (cdr ct) (cdr cs))))))
             all-tags))

      (syntax-case stx ()
        ((_ type-name
            (constructor-name ctor-field ...)
            predicate-name
            field-spec ...)

         (let* ((fds    ; (tag accessor-stx mutator-stx-or-#f) list
                 (map (lambda (fs)
                        (syntax-case fs ()
                          ((t a)   (list (syntax->datum #'t) #'a #f))
                          ((t a m) (list (syntax->datum #'t) #'a #'m))))
                      (syntax->list #'(field-spec ...))))

                (all-tags  (map car fds))
                (ctor-tags (map syntax->datum (syntax->list #'(ctor-field ...))))
                (ctor-stxs (syntax->list #'(ctor-field ...)))

                (fvec      ; #((mutable|immutable tag) ...)
                 (list->vector
                  (map (lambda (fd)
                         (list (if (caddr fd) 'mutable 'immutable) (car fd)))
                       fds)))

                (new-args  (build-new-args all-tags ctor-tags ctor-stxs))

                (tsym      (syntax->datum #'type-name))
                (rtd-sym   (string->symbol (string-append (symbol->string tsym) "-rtd")))
                (rcd-sym   (string->symbol (string-append (symbol->string tsym) "-rcd"))))

           (with-syntax
             ((rtd-id      (datum->syntax #'type-name rtd-sym))
              (rcd-id      (datum->syntax #'type-name rcd-sym))
              (fvec-datum  (datum->syntax #'type-name fvec))
              (new-call    #`(new #,@new-args)))

             ;; Accumulate accessor/mutator defines by iterating the field list
             (let loop ((fds fds) (idx 0) (defs '()))
               (if (null? fds)
                   ;; Emit the final expansion
                   #`(begin
                       (define rtd-id
                         (make-record-type-descriptor
                           'type-name #f #f #f #f 'fvec-datum))
                       (define rcd-id
                         (make-record-constructor-descriptor
                           rtd-id #f
                           (lambda (new)
                             (lambda (ctor-field ...)
                               new-call))))
                       (define constructor-name (record-constructor rcd-id))
                       (define predicate-name   (record-predicate   rtd-id))
                       #,@(reverse defs))
                   ;; Accumulate accessor (and optional mutator) for this field
                   (let* ((fd  (car fds))
                          (acc #`(define #,(cadr fd)  (record-accessor rtd-id #,idx)))
                          (mut (and (caddr fd)
                                    #`(define #,(caddr fd) (record-mutator rtd-id #,idx)))))
                     (loop (cdr fds)
                           (+ idx 1)
                           (if mut
                               (cons mut (cons acc defs))
                               (cons acc defs)))))))))))))
