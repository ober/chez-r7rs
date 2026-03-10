;;; (scheme r5rs) — R7RS §R5RS compatibility library
;;; Exports the ~80 R5RS standard identifiers.

(library (scheme r5rs)
  (export
    ;; Equivalence
    eq? eqv? equal?
    ;; Numbers
    number? complex? real? rational? integer?
    exact? inexact?
    = < > <= >=
    zero? positive? negative? odd? even?
    max min + - * /
    abs gcd lcm
    numerator denominator
    floor ceiling truncate round rationalize
    exact->inexact inexact->exact
    number->string string->number
    expt sqrt
    ;; Booleans
    boolean? not
    ;; Pairs
    pair? cons car cdr set-car! set-cdr!
    caar cadr cdar cddr
    caaar caadr cadar caddr cdaar cdadr cddar cdddr
    caaaar caaadr caadar caaddr cadaar cadadr caddar cadddr
    cdaaar cdaadr cdadar cdaddr cddaar cddadr cdddar cddddr
    ;; Lists
    null? list? list length append reverse
    list-tail list-ref
    map for-each
    ;; Symbols
    symbol? symbol->string string->symbol
    ;; Characters
    char? char=? char<? char>? char<=? char>=?
    char-ci=? char-ci<? char-ci>? char-ci<=? char-ci>=?
    char-alphabetic? char-numeric? char-whitespace?
    char-upper-case? char-lower-case?
    char->integer integer->char char-upcase char-downcase
    ;; Strings
    string? make-string string
    string-length string-ref string-set!
    string=? string<? string>? string<=? string>=?
    string-ci=? string-ci<? string-ci>? string-ci<=? string-ci>=?
    substring string-append string->list list->string
    string-copy string-fill!
    ;; Vectors
    vector? make-vector vector vector-length
    vector-ref vector-set! vector->list list->vector vector-fill!
    ;; Control
    procedure? apply values
    call-with-current-continuation call-with-values dynamic-wind
    ;; I/O
    read write display newline read-char peek-char write-char
    char-ready? eof-object? eof-object
    input-port? output-port?
    current-input-port current-output-port
    open-input-file open-output-file
    close-input-port close-output-port
    call-with-input-file call-with-output-file
    with-input-from-file with-output-to-file
    ;; Exceptions (R5RS has error)
    error
    ;; Eval
    eval interaction-environment
    null-environment scheme-report-environment
    ;; Misc
    assq assv assoc memq memv member
    for-each
    )
  (import
    (scheme base)
    (scheme char)
    (scheme cxr)
    (scheme eval)
    (scheme read)
    (scheme write)
    (scheme file)
    (scheme repl)
    (rename (only (chezscheme) null-environment scheme-report-environment)
      (null-environment chez:null-environment)
      (scheme-report-environment chez:scheme-report-environment)))

  ;; R5RS null-environment: returns an environment with only syntactic bindings
  (define (null-environment n)
    (chez:null-environment n))

  ;; R5RS scheme-report-environment: returns the standard environment for version n
  (define (scheme-report-environment n)
    (chez:scheme-report-environment n))
)
