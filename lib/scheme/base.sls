;;; (scheme base) — R7RS §6
;;; The main R7RS library. Provides ~150 exports.
;;; Strategy: import (chezscheme), re-export compatible names, wrap/replace where needed.

(library (scheme base)
  (export
    ;; === Equivalence ===
    eq? eqv? equal?

    ;; === Numbers ===
    number? complex? real? rational? integer?
    exact? inexact? exact-integer?
    exact inexact exact->inexact inexact->exact
    = < > <= >=
    zero? positive? negative? odd? even?
    max min + - * /
    abs gcd lcm
    numerator denominator
    floor ceiling truncate round
    rationalize
    square
    exact-integer-sqrt
    expt sqrt
    floor/ floor-quotient floor-remainder
    truncate/ truncate-quotient truncate-remainder
    number->string string->number

    ;; === Booleans ===
    boolean? not boolean=?

    ;; === Pairs & Lists ===
    pair? cons car cdr
    set-car! set-cdr!
    caar cadr cdar cddr
    null? list? list
    make-list list-copy
    length append reverse
    list-tail list-ref list-set!
    map for-each
    list->string list->vector
    string->list vector->list
    assq assv assoc
    memq memv member

    ;; === Characters ===
    char? char=? char<? char>? char<=? char>=?
    char->integer integer->char
    char-upcase char-downcase
    char-alphabetic? char-numeric? char-whitespace?
    char-upper-case? char-lower-case?

    ;; === Strings ===
    string? make-string string string-length string-ref string-set!
    string=? string<? string>? string<=? string>=?
    substring string-append string->list list->string
    string-copy string-copy! string-fill!
    string-upcase string-downcase
    string->number number->string
    string->symbol symbol->string
    string->utf8 utf8->string
    string-map string-for-each

    ;; === Vectors ===
    vector? make-vector vector vector-length vector-ref vector-set!
    vector->list list->vector vector-fill!
    vector-copy vector-copy! vector-append
    vector-map vector-for-each

    ;; === Bytevectors ===
    bytevector? make-bytevector bytevector
    bytevector-length bytevector-u8-ref bytevector-u8-set!
    bytevector-copy bytevector-copy! bytevector-append
    utf8->string string->utf8

    ;; === Symbols ===
    symbol? symbol->string string->symbol symbol=?

    ;; === Control ===
    procedure? apply values call-with-values
    call-with-current-continuation call/cc
    dynamic-wind
    not

    ;; === Ports ===
    port? input-port? output-port? textual-port? binary-port?
    input-port-open? output-port-open?
    current-input-port current-output-port current-error-port
    close-input-port close-output-port close-port
    open-input-string open-output-string get-output-string
    open-input-bytevector open-output-bytevector get-output-bytevector
    open-binary-input-file open-binary-output-file
    open-input-file open-output-file
    flush-output-port
    read-line
    read-char peek-char char-ready?
    write-char
    read-u8 peek-u8 u8-ready? write-u8
    read-bytevector read-bytevector! write-bytevector
    newline
    eof-object? eof-object

    ;; === I/O ===
    with-exception-handler raise raise-continuable
    guard error error-object? error-object-message error-object-irritants
    read-error? file-error?
    features

    ;; === Definitions & Syntax ===
    define define-syntax define-values define-record-type
    lambda let let* letrec letrec* let-values let*-values
    begin if cond case and or when unless
    do set!
    quote quasiquote unquote unquote-splicing
    case-lambda
    include include-ci
    cond-expand
    let-syntax letrec-syntax
    syntax-rules syntax-error

    ;; === Parameters ===
    make-parameter parameterize

    ;; === Lazy (also in scheme lazy) ===
    delay delay-force force make-promise promise?

    ;; === Misc ===
    void not error
    )

  (import
    ;; Import (chezscheme) but exclude names we're replacing with R7RS versions
    (rename (except (chezscheme)
               error              ; different signature (no who arg in R7RS)
               define-record-type ; different syntax (SRFI-9 vs R6RS)
               bytevector-copy!   ; different argument order (Chez: src-first)
               bytevector-copy    ; need optional start/end args
               string-copy        ; need optional start/end args
               string-copy!       ; different argument order (Chez: src-first)
               vector-copy        ; Chez 3-arg version uses different convention
               vector-copy!       ; Chez version is src-first (R6RS style)
               boolean=?          ; provide R7RS-compatible multi-arg version
               symbol=?           ; same
               make-list          ; provide R7RS version (fill default is #f)
               list-copy          ; provide R7RS version
               exact-integer-sqrt ; provide R7RS version with correction
               string-for-each    ; Chez errors on unequal-length strings
               flush-output-port  ; Chez requires exactly 1 arg
               close-port         ; also exported from (r7rs internal ports)
               delay              ; use our R7RS promise implementation
               force              ; use our R7RS force
               )
             ;; Import assoc/member under different names so we can wrap them
             (assoc chez:assoc)
             (member chez:member))
    ;; Internal support modules
    (r7rs internal error-objects)
    (r7rs internal promises)
    (r7rs internal record-type)
    (r7rs internal bytevector-compat)
    (r7rs internal division)
    (r7rs internal ports)
    (r7rs internal write)
    (r7rs features)
    )

  ;; === Error ===
  ;; R7RS error: (error message irritant ...)
  (define error r7rs:error)

  ;; === define-record-type (SRFI-9 style) ===
  (define-syntax define-record-type
    (syntax-rules ()
      ((_ . rest) (r7rs:define-record-type . rest))))

  ;; === bytevector-copy! and bytevector-copy ===
  (define bytevector-copy!  r7rs:bytevector-copy!)
  (define bytevector-copy   r7rs:bytevector-copy)

  ;; === string-copy with optional range ===
  (define string-copy  r7rs:string-copy)
  (define string-copy! r7rs:string-copy!)

  ;; === Port procedures from (r7rs internal ports) ===
  (define flush-output-port r7rs:flush-output-port)

  ;; === New numeric procedures ===

  (define (square x) (* x x))

  (define (exact-integer? x)
    (and (integer? x) (exact? x)))

  (define (exact-integer-sqrt k)
    (let ((s (exact (floor (sqrt (exact->inexact k))))))
      ;; Correct for floating-point rounding
      (let loop ((s s))
        (cond
          ((> (* s s) k) (loop (- s 1)))
          ((> (* (+ s 1) (+ s 1)) k) (values s (- k (* s s))))
          (else (loop (+ s 1)))))))

  ;; === Boolean procedures ===
  (define (boolean=? b1 b2 . rest)
    (if (and (boolean? b1) (boolean? b2) (eq? b1 b2))
        (if (null? rest)
            #t
            (apply boolean=? b2 rest))
        #f))

  ;; === Symbol procedures ===
  (define (symbol=? s1 s2 . rest)
    (if (and (symbol? s1) (symbol? s2) (eq? s1 s2))
        (if (null? rest)
            #t
            (apply symbol=? s2 rest))
        #f))

  ;; === List procedures ===

  (define (make-list k . args)
    (let ((fill (if (null? args) #f (car args))))
      (let loop ((i k) (acc '()))
        (if (= i 0) acc
            (loop (- i 1) (cons fill acc))))))

  (define (list-copy lst)
    (if (pair? lst)
        (cons (car lst) (list-copy (cdr lst)))
        lst))

  (define (list-set! lst k obj)
    (set-car! (list-tail lst k) obj))

  ;; === assoc and member with optional comparator ===
  ;; chez:assoc and chez:member are imported via rename above.

  (define (assoc obj lst . args)
    (if (null? args)
        (chez:assoc obj lst)
        (let ((compare (car args)))
          (let loop ((lst lst))
            (cond
              ((null? lst) #f)
              ((compare obj (caar lst)) (car lst))
              (else (loop (cdr lst))))))))

  (define (member obj lst . args)
    (if (null? args)
        (chez:member obj lst)
        (let ((compare (car args)))
          (let loop ((lst lst))
            (cond
              ((null? lst) #f)
              ((compare obj (car lst)) lst)
              (else (loop (cdr lst))))))))

  ;; === String procedures ===

  (define (string-map f s . rest)
    (if (null? rest)
        (let* ((len (string-length s))
               (result (make-string len)))
          (do ((i 0 (+ i 1)))
              ((= i len) result)
            (string-set! result i (f (string-ref s i)))))
        ;; Multi-string case: stop at shortest
        (let* ((strings (cons s rest))
               (len (apply min (map string-length strings)))
               (result (make-string len)))
          (do ((i 0 (+ i 1)))
              ((= i len) result)
            (string-set! result i
                         (apply f (map (lambda (str) (string-ref str i)) strings)))))))

  (define (string-for-each f s . rest)
    (if (null? rest)
        (let ((len (string-length s)))
          (do ((i 0 (+ i 1)))
              ((= i len))
            (f (string-ref s i))))
        (let* ((strings (cons s rest))
               (len (apply min (map string-length strings))))
          (do ((i 0 (+ i 1)))
              ((= i len))
            (apply f (map (lambda (str) (string-ref str i)) strings))))))

  ;; === Vector procedures ===

  (define (vector-copy v . args)
    (let* ((start (if (null? args) 0 (car args)))
           (end   (if (or (null? args) (null? (cdr args)))
                      (vector-length v) (cadr args)))
           (len   (- end start))
           (result (make-vector len)))
      (do ((i 0 (+ i 1)))
          ((= i len) result)
        (vector-set! result i (vector-ref v (+ start i))))))

  (define (vector-copy! to at from . args)
    (let* ((start (if (null? args) 0 (car args)))
           (end   (if (or (null? args) (null? (cdr args)))
                      (vector-length from) (cadr args)))
           (len   (- end start)))
      ;; Handle overlapping regions by copying front-to-back or back-to-front
      (if (or (not (eq? to from)) (< at start))
          (do ((i 0 (+ i 1)))
              ((= i len))
            (vector-set! to (+ at i) (vector-ref from (+ start i))))
          (do ((i (- len 1) (- i 1)))
              ((< i 0))
            (vector-set! to (+ at i) (vector-ref from (+ start i)))))))

  ;; vector-append is compatible in Chez; re-exported from (chezscheme)

  ;; === Bytevector append ===
  (define (bytevector-append . bvs)
    (let* ((lengths (map bytevector-length bvs))
           (total   (apply + lengths))
           (result  (make-bytevector total)))
      (let loop ((bvs bvs) (pos 0))
        (if (null? bvs)
            result
            (let ((bv (car bvs)))
              (do ((i 0 (+ i 1)))
                  ((= i (bytevector-length bv)))
                (bytevector-u8-set! result (+ pos i) (bytevector-u8-ref bv i)))
              (loop (cdr bvs) (+ pos (bytevector-length bv))))))))

  ;; === Close-port ===
  ;; Already exported from (r7rs internal ports)

  ;; === Features ===
  (define (features) r7rs-features)

  ;; === Lazy evaluation ===
  (define-syntax delay
    (syntax-rules ()
      ((_ expr)
       (make-r7rs-promise 'lazy (lambda () expr)))))

  (define-syntax delay-force
    (syntax-rules ()
      ((_ expr)
       (make-r7rs-promise 'lazy (lambda () expr)))))

  (define force r7rs:force)
  (define make-promise r7rs:make-promise)
  (define promise? r7rs-promise?)

  ;; define-values, syntax-error, and include are provided by (chezscheme).
  ;; They are R7RS-compatible in Chez 10.4.

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

  ;; === cond-expand ===
  ;; Works at expression level. Feature checks happen at expansion time.
  (define-syntax cond-expand
    (lambda (x)
      (define (feature-available? req)
        (cond
          ((symbol? req)
           (memq req r7rs-features))
          ((pair? req)
           (case (car req)
             ((and) (every feature-available? (cdr req)))
             ((or)  (any  feature-available? (cdr req)))
             ((not) (not (feature-available? (cadr req))))
             ((library) #t) ;; optimistic: assume library exists
             (else #f)))
          (else #f)))
      (define (every pred lst)
        (or (null? lst)
            (and (pred (car lst)) (every pred (cdr lst)))))
      (define (any pred lst)
        (and (not (null? lst))
             (or (pred (car lst)) (any pred (cdr lst)))))
      (syntax-case x (else)
        ((_ (else body ...))
         #'(begin body ...))
        ((_ (req body ...) rest ...)
         (if (feature-available? (syntax->datum #'req))
             #'(begin body ...)
             #'(cond-expand rest ...)))
        ((_)
         (syntax-violation 'cond-expand "no matching clause" x)))))
)
