# chez-r7rs: Full R7RS Implementation on ChezScheme

## Architecture Plan

### Overview

Implement the complete R7RS-small standard as a library layer on top of ChezScheme's
R6RS foundation. The approach is **wrapper libraries + syntax transformer**: each of the
16 `(scheme ...)` libraries is implemented as an R6RS `library` form that re-exports
Chez bindings (adapting semantics where they differ), and a `define-library` macro
translates R7RS module syntax into R6RS `library` forms.

**Design principles:**
- Zero modifications to ChezScheme's source tree
- Pure Scheme implementation (no C code, no FFI)
- Each R7RS library is a standalone `.sls` file loadable by Chez
- Passes the R7RS test suite (Chibi's r7rs-tests or equivalent)

---

## 1. Project Structure

```
chez-r7rs/
├── plan.md                          # This file
├── Makefile                         # Build & test orchestration
├── README.md                        # Usage documentation
├── lib/
│   └── scheme/                      # R7RS standard libraries
│       ├── base.sls                 # (scheme base) — the big one
│       ├── case-lambda.sls          # (scheme case-lambda)
│       ├── char.sls                 # (scheme char)
│       ├── complex.sls              # (scheme complex)
│       ├── cxr.sls                  # (scheme cxr)
│       ├── eval.sls                 # (scheme eval)
│       ├── file.sls                 # (scheme file)
│       ├── inexact.sls              # (scheme inexact)
│       ├── lazy.sls                 # (scheme lazy)
│       ├── load.sls                 # (scheme load)
│       ├── process-context.sls      # (scheme process-context)
│       ├── r5rs.sls                 # (scheme r5rs)
│       ├── read.sls                 # (scheme read)
│       ├── repl.sls                 # (scheme repl)
│       ├── time.sls                 # (scheme time)
│       └── write.sls               # (scheme write)
├── lib/r7rs/
│   ├── define-library.sls           # define-library macro
│   ├── cond-expand.sls              # cond-expand support
│   ├── include.sls                  # include / include-ci
│   └── features.sls                 # Feature identifiers registry
├── lib/r7rs/internal/
│   ├── error-objects.sls            # R7RS error object types
│   ├── promises.sls                 # R7RS lazy evaluation (delay-force)
│   ├── bytevector-compat.sls        # bytevector-copy! argument adaptation
│   ├── record-type.sls              # SRFI-9 define-record-type
│   ├── division.sls                 # floor/, truncate/ etc.
│   ├── ports.sls                    # R7RS port procedures
│   └── write.sls                    # write-shared, write-simple
├── tests/
│   ├── run-all.ss                   # Test runner
│   ├── r7rs-tests.ss                # Adapted Chibi r7rs-tests
│   ├── base-test.ss                 # (scheme base) tests
│   ├── char-test.ss                 # (scheme char) tests
│   ├── lazy-test.ss                 # (scheme lazy) tests
│   ├── write-test.ss                # (scheme write) tests
│   ├── define-library-test.ss       # define-library tests
│   └── ...                          # One test per library
└── examples/
    ├── hello.sls                    # Basic R7RS program
    └── cond-expand-demo.sls         # Feature detection example
```

The `lib/` directory is added to Chez's `--libdirs` or `(library-directories)` so
that `(import (scheme base))` resolves to `lib/scheme/base.sls`.

---

## 2. Compatibility Analysis: What Chez Already Provides

### 2.1 Direct Re-exports (No Adaptation Needed)

The majority of R7RS procedures exist in Chez with identical semantics. These can be
directly re-exported from `(chezscheme)`:

**Arithmetic & Numeric:** `+`, `-`, `*`, `/`, `=`, `<`, `>`, `<=`, `>=`, `zero?`,
`positive?`, `negative?`, `odd?`, `even?`, `abs`, `max`, `min`, `gcd`, `lcm`,
`numerator`, `denominator`, `floor`, `ceiling`, `truncate`, `round`, `rationalize`,
`exact`, `inexact`, `exact->inexact`, `inexact->exact`, `number->string`,
`string->number`, `number?`, `complex?`, `real?`, `rational?`, `integer?`, `exact?`,
`inexact?`, `remainder`, `quotient`, `modulo`

**Pairs & Lists:** `cons`, `car`, `cdr`, `pair?`, `null?`, `list?`, `list`, `length`,
`append`, `reverse`, `map`, `for-each`, `memq`, `memv`, `member`, `assq`, `assv`,
`assoc`, `list-tail`, `list-ref`, `list->vector`, `list->string`

**Vectors:** `vector?`, `make-vector`, `vector`, `vector-length`, `vector-ref`,
`vector-set!`, `vector->list`, `vector-fill!`

**Strings:** `string?`, `make-string`, `string`, `string-length`, `string-ref`,
`string-set!`, `string->list`, `list->string`, `string-append`, `substring`,
`string-copy`, `string-fill!`, `string->symbol`, `symbol->string`, `string->number`,
`number->string`

**Characters:** `char?`, `char=?`, `char<?`, `char>?`, `char<=?`, `char>=?`,
`char->integer`, `integer->char`

**Booleans:** `boolean?`, `not`

**Symbols:** `symbol?`, `symbol->string`, `string->symbol`

**Control:** `procedure?`, `apply`, `call-with-current-continuation`,
`call-with-values`, `values`, `dynamic-wind`

**I/O (basic):** `input-port?`, `output-port?`, `current-input-port`,
`current-output-port`, `current-error-port`, `open-input-file`, `open-output-file`,
`close-input-port`, `close-output-port`, `read-char`, `peek-char`, `char-ready?`,
`write-char`, `newline`, `eof-object?`, `eof-object`

**Syntax:** `case-lambda`, `syntax-rules`, `let-syntax`, `letrec-syntax`,
`let`, `let*`, `letrec`, `letrec*`, `begin`, `do`, `define`, `define-syntax`,
`lambda`, `if`, `cond`, `case`, `and`, `or`, `when`, `unless`, `set!`, `quote`,
`quasiquote`, `unquote`, `unquote-splicing`

**Exceptions:** `with-exception-handler`, `raise`, `raise-continuable`, `guard`

**Parameters:** `make-parameter`, `parameterize`

**Equivalence:** `eq?`, `eqv?`, `equal?`

### 2.2 Semantic Adaptations Required

These exist in Chez but with different signatures, behavior, or names:

| R7RS Procedure | Chez Equivalent | Adaptation |
|---|---|---|
| `bytevector-copy!` (to at from [start [end]]) | `bytevector-copy!` (src ss dst ds k) | **Argument order reversed + optional args** |
| `bytevector-copy` (bv [start [end]]) | `bytevector-copy` (bv) | Add optional start/end |
| `string-copy` (s [start [end]]) | `string-copy` (s) | Add optional start/end |
| `string-copy!` (to at from [start [end]]) | N/A | New implementation needed |
| `vector-copy` (v [start [end]]) | N/A | New implementation |
| `vector-copy!` (to at from [start [end]]) | N/A | New implementation |
| `vector-append` (v ...) | N/A | New implementation |
| `assoc` (obj list [compare]) | `assoc` (obj list) | Add optional comparator |
| `member` (obj list [compare]) | `member` (obj list) | Add optional comparator |
| `map` (f list1 ...) | `map` (f list1 ...) | Same, but R7RS allows unequal-length lists (stops at shortest) |
| `for-each` (f list1 ...) | `for-each` (f list1 ...) | Same unequal-length adaptation |
| `read` ([port]) | `read` ([port]) | Must return R7RS datum labels `#n=`/`#n#` syntax |
| `error` (msg irritant ...) | `error` (who msg irritant ...) | R7RS has no `who` argument |
| `string->number` (s [radix]) | `string->number` (s [radix]) | Verify edge cases |
| `char-ready?` | `char-ready?` | Verify matches R7RS |
| `close-port` | N/A | New (closes either direction) |
| `open-binary-input-file` | `open-file-input-port` | Wrapper with R7RS semantics |
| `open-binary-output-file` | `open-file-output-port` | Wrapper with R7RS semantics |
| `define-record-type` | R6RS `define-record-type` | **Completely different syntax** (SRFI-9 style) |
| `include` | N/A | New macro |
| `include-ci` | N/A | New macro |
| `cond-expand` | N/A | New macro |
| `define-library` | `library` | Syntax transformer |
| `define-values` | N/A | New macro |

### 2.3 Entirely New Implementations Required

| R7RS Feature | Notes |
|---|---|
| `delay-force` | Iterative forcing (R7RS's improved lazy evaluation) |
| `make-promise`, `promise?` | R7RS promise type (distinct from Chez's) |
| `error-object?`, `error-object-message`, `error-object-irritants` | Wrap Chez conditions |
| `read-error?`, `file-error?` | Map to Chez condition predicates |
| `features` | Return list of feature identifiers |
| `square` | `(define (square x) (* x x))` |
| `exact-integer?` | `(define (exact-integer?) (and (integer? x) (exact? x)))` |
| `boolean=?` | New |
| `symbol=?` | New |
| `floor/`, `floor-quotient`, `floor-remainder` | Division with floor semantics |
| `truncate/`, `truncate-quotient`, `truncate-remainder` | Division with truncate semantics |
| `exact-integer-sqrt` | Integer square root returning two values |
| `read-line` | Read until newline |
| `read-u8`, `peek-u8`, `u8-ready?`, `write-u8` | Binary I/O primitives |
| `read-bytevector`, `read-bytevector!`, `write-bytevector` | Binary bulk I/O |
| `open-input-bytevector`, `open-output-bytevector`, `get-output-bytevector` | Bytevector ports |
| `open-input-string`, `open-output-string`, `get-output-string` | String ports (Chez has these) |
| `textual-port?`, `binary-port?` | Port type predicates |
| `input-port-open?`, `output-port-open?` | Port state predicates |
| `flush-output-port` | `(flush-output-port [port])` |
| `write-shared` | Write with datum labels for cycles |
| `write-simple` | Write without datum labels |
| `string-map`, `string-for-each` | String iteration |
| `vector-map`, `vector-for-each` | Vector iteration (Chez has these) |
| `list-copy` | Shallow copy |
| `list-set!` | Set list element by index |
| `make-list` | Create list of length k |
| `syntax-error` | Compile-time error in macros |
| `let-values`, `let*-values` | Multiple-value binding (Chez has in R6RS) |
| `current-second` | TAI seconds since epoch |
| `current-jiffy`, `jiffies-per-second` | High-resolution timing |
| `emergency-exit` | Immediate exit without cleanup |
| `get-environment-variable`, `get-environment-variables` | Env access |

---

## 3. Implementation Strategy by Library

### Phase 1: Foundation (Weeks 1-2)

#### 3.1 Internal Support Libraries

Build the internal machinery first since `(scheme base)` depends on it.

**`lib/r7rs/internal/error-objects.sls`** — R7RS error object bridge

R7RS `error` has signature `(error message irritant ...)` (no `who` parameter).
Chez's `error` is `(error who message irritant ...)`. Strategy:

```scheme
(library (r7rs internal error-objects)
  (export r7rs:error error-object? error-object-message
          error-object-irritants error-object-type
          read-error? file-error?)
  (import (chezscheme))

  ;; R7RS error creates a Chez condition with who='r7rs
  (define (r7rs:error message . irritants)
    (raise
      (condition
        (make-error)
        (make-who-condition 'r7rs)
        (make-message-condition message)
        (make-irritants-condition irritants))))

  ;; Predicates that work on Chez condition objects
  (define (error-object? obj)
    (and (condition? obj)
         (error? obj)))

  (define (error-object-message obj)
    (if (message-condition? obj)
        (condition-message obj)
        ""))

  (define (error-object-irritants obj)
    (if (irritants-condition? obj)
        (condition-irritants obj)
        '()))

  (define (read-error? obj)
    (and (condition? obj)
         (lexical-violation? obj)))

  (define (file-error? obj)
    (and (condition? obj)
         (i/o-error? obj)))
)
```

**`lib/r7rs/internal/promises.sls`** — R7RS lazy evaluation

R7RS `delay-force` enables iterative forcing (avoids stack overflow on
deeply-nested lazy sequences). This requires a distinct promise type from
Chez's built-in `delay`/`force`.

```scheme
;; Promise is a mutable pair: (tag . value)
;; tag = 'lazy    -> value is a thunk
;; tag = 'eager   -> value is the forced result
;; tag = 'forcing -> value is a thunk (re-entrant guard)

(define-record-type r7rs-promise (fields (mutable tag) (mutable value)))

(define (make-promise obj)
  (if (r7rs-promise? obj)
      obj
      (make-r7rs-promise 'eager obj)))

(define (r7rs:delay thunk)     ;; macro wraps in thunk
  (make-r7rs-promise 'lazy thunk))

(define (r7rs:delay-force thunk)  ;; macro wraps in thunk
  (make-r7rs-promise 'lazy thunk))

(define (r7rs:force promise)
  (let loop ((p promise))
    (case (r7rs-promise-tag p)
      ((eager) (r7rs-promise-value p))
      ((lazy)
       (r7rs-promise-tag-set! p 'forcing)
       (let ((result ((r7rs-promise-value p))))
         (if (r7rs-promise? result)
             ;; delay-force case: adopt the inner promise's content
             (begin
               (r7rs-promise-tag-set! p (r7rs-promise-tag result))
               (r7rs-promise-value-set! p (r7rs-promise-value result))
               ;; Make inner promise point to outer (forwarding)
               (r7rs-promise-tag-set! result (r7rs-promise-tag p))
               (r7rs-promise-value-set! result (r7rs-promise-value p))
               (loop p))
             (begin
               (r7rs-promise-tag-set! p 'eager)
               (r7rs-promise-value-set! p result)
               result))))
      ((forcing) (error "force" "re-entrant promise"))
      (else (error "force" "not a promise" p)))))
```

The key insight: `delay-force` creates a promise that, when forced, produces another
promise. `force` iteratively unwraps these without growing the stack (trampolining).

**`lib/r7rs/internal/record-type.sls`** — SRFI-9 `define-record-type`

Chez's R6RS `define-record-type` has completely different syntax. We implement SRFI-9
style using `syntax-rules`:

```scheme
(define-syntax r7rs:define-record-type
  (syntax-rules ()
    ((_ type-name
        (constructor-name field-tag ...)
        predicate-name
        field-spec ...)
     (begin
       ;; Use Chez's record system underneath
       (define-record type-name (field-tag ...))  ;; Chez non-R6RS shorthand
       ;; ... or expand to full procedural record creation
       ))))
```

Implementation detail: Use Chez's procedural record API (`make-record-type-descriptor`)
under the hood, with `syntax-case` to parse the SRFI-9 field specifications and
generate accessors/mutators with the user-specified names.

**`lib/r7rs/internal/bytevector-compat.sls`** — bytevector-copy! adaptation

```scheme
;; R7RS:  (bytevector-copy! to at from)           — destination first
;; R7RS:  (bytevector-copy! to at from start)     — with source start
;; R7RS:  (bytevector-copy! to at from start end) — with source range
;; Chez:  (bytevector-copy! src ss dst ds count)  — source first, explicit count

(define r7rs:bytevector-copy!
  (case-lambda
    ((to at from)
     (bytevector-copy! from 0 to at (bytevector-length from)))
    ((to at from start)
     (bytevector-copy! from start to at (- (bytevector-length from) start)))
    ((to at from start end)
     (bytevector-copy! from start to at (- end start)))))
```

**`lib/r7rs/internal/division.sls`** — Floor and truncate division

```scheme
(define (floor/ n d)
  (values (floor-quotient n d) (floor-remainder n d)))
(define (floor-quotient n d)
  (floor (/ n d)))
(define (floor-remainder n d)
  (- n (* d (floor-quotient n d))))
(define (truncate/ n d)
  (values (truncate-quotient n d) (truncate-remainder n d)))
(define (truncate-quotient n d)
  (truncate (/ n d)))
(define (truncate-remainder n d)
  (- n (* d (truncate-quotient n d))))
```

**`lib/r7rs/internal/ports.sls`** — R7RS I/O procedures

Map R7RS binary/textual port API to Chez's R6RS port infrastructure:

```scheme
(define (open-binary-input-file filename)
  (open-file-input-port filename))
(define (open-binary-output-file filename)
  (open-file-output-port filename))
(define (open-input-bytevector bv)
  (open-bytevector-input-port bv))
(define open-input-string open-string-input-port)    ;; Chez name
(define open-output-string open-string-output-port)
(define (get-output-string port) (get-output-string port))
;; ... etc.
```

Binary I/O:
```scheme
(define (read-u8 . args)
  (let ((port (if (null? args) (current-input-port) (car args))))
    (get-u8 port)))
(define (peek-u8 . args) ...)
(define (write-u8 byte . args) ...)
(define (read-bytevector k . args)
  (let ((port (if (null? args) (current-input-port) (car args))))
    (get-bytevector-n port k)))
(define read-line get-line)  ;; Chez has get-line
```

**`lib/r7rs/internal/write.sls`** — R7RS write variants

```scheme
;; write-shared: write with datum labels for shared structure
;; Chez's (print-graph #t) parameter controls this
(define (write-shared obj . args)
  (let ((port (if (null? args) (current-output-port) (car args))))
    (parameterize ((print-graph #t))
      (write obj port))))

;; write-simple: write without datum labels (no cycle detection)
(define (write-simple obj . args)
  (let ((port (if (null? args) (current-output-port) (car args))))
    (parameterize ((print-graph #f))
      (write obj port))))
```

#### 3.2 Feature Registry

**`lib/r7rs/features.sls`**

```scheme
(library (r7rs features)
  (export r7rs-features)
  (import (chezscheme))
  (define r7rs-features
    '(r7rs
      exact-closed exact-complex
      ieee-float
      ratios
      full-unicode
      ;; Platform detection
      ,@(case (machine-type)
          [(ta6le ti3le a6le i3le arm64le arm32le
            a6fb i3fb a6ob i3ob a6nb i3nb) '(posix)]
          [(ta6nt ti3nt a6nt i3nt) '(windows)]
          [else '()])
      chez-scheme)))
```

### Phase 2: Core Libraries (Weeks 2-4)

#### 3.3 `(scheme base)` — The Main Library (~200 exports)

This is the largest and most critical library. Strategy: import from `(chezscheme)`,
re-export matching names, override/wrap where semantics differ.

**Structure of `lib/scheme/base.sls`:**

```scheme
(library (scheme base)
  (export
    ;; === Direct re-exports from Chez ===
    * + - / < <= = > >= abs and append apply
    begin boolean? bytevector? call-with-current-continuation
    call-with-port call-with-values call/cc car case cdr
    ceiling char->integer char? close-input-port close-output-port
    complex? cond cons current-error-port current-input-port
    current-output-port define define-syntax denominator
    do dynamic-wind eof-object eof-object? eq? equal? eqv?
    even? exact exact->inexact exact? expt floor for-each gcd
    if inexact inexact->exact inexact? input-port? integer?
    integer->char lambda lcm length let let* let-syntax
    letrec letrec* letrec-syntax list list->string list->vector
    list-ref list-tail list? map max min modulo negative?
    newline not null? number? number->string numerator odd?
    or output-port? pair? peek-char positive? procedure?
    quasiquote quote quotient rational? rationalize read-char
    real? remainder reverse round set! string string->list
    string->number string->symbol string->utf8 string-append
    string-copy string-fill! string-length string-ref string-set!
    string? substring symbol->string symbol? truncate
    unquote unquote-splicing utf8->string values vector
    vector->list vector-fill! vector-for-each vector-length
    vector-map vector-ref vector-set! vector? when unless
    with-exception-handler write-char zero?
    char-ready? char=? char<? char>? char<=? char>=?

    ;; === R7RS syntax (some from Chez, some new) ===
    case-lambda let-values let*-values define-values
    guard raise raise-continuable parameterize
    syntax-rules syntax-error
    define-record-type          ; SRFI-9 style (our implementation)
    include include-ci
    cond-expand

    ;; === R7RS-specific procedures (our implementations) ===
    error                       ; R7RS version (no who)
    error-object? error-object-message error-object-irritants
    read-error? file-error?
    features
    square exact-integer? exact-integer-sqrt
    boolean=? symbol=?
    floor/ floor-quotient floor-remainder
    truncate/ truncate-quotient truncate-remainder
    make-list list-copy list-set!
    string-map string-for-each
    string-copy!
    vector-copy vector-copy! vector-append
    bytevector bytevector-append bytevector-copy bytevector-copy!
    bytevector-length bytevector-u8-ref bytevector-u8-set!
    make-bytevector
    ;; I/O
    close-port
    open-input-string open-output-string get-output-string
    open-input-bytevector open-output-bytevector get-output-bytevector
    open-binary-input-file open-binary-output-file
    read-line read-u8 peek-u8 u8-ready? write-u8
    read-bytevector read-bytevector! write-bytevector
    flush-output-port
    textual-port? binary-port?
    input-port-open? output-port-open?
    ;; Parameters
    make-parameter
    ;; Promises (delay/force are exported as syntax)
    ;; delay delay-force force make-promise promise?
  )
  (import
    (except (chezscheme)
      error                     ; different signature
      define-record-type        ; different syntax
      bytevector-copy!          ; different argument order
      bytevector-copy           ; need optional args
      syntax-rules              ; use R7RS version (with _)
      ;; ... other overrides
    )
    (r7rs internal error-objects)
    (r7rs internal promises)
    (r7rs internal record-type)
    (r7rs internal bytevector-compat)
    (r7rs internal division)
    (r7rs internal ports)
    (r7rs features)
  )

  ;; Rename imports
  ;; (rename (r7rs:error error) ...)

  ;; === Inline implementations for simple procedures ===

  (define (square x) (* x x))

  (define (exact-integer? x)
    (and (integer? x) (exact? x)))

  (define (boolean=? b1 b2 . rest)
    (and (boolean? b1) (boolean? b2)
         (eq? b1 b2)
         (or (null? rest) (apply boolean=? b2 rest))))

  (define (symbol=? s1 s2 . rest)
    (and (symbol? s1) (symbol? s2)
         (eq? s1 s2)
         (or (null? rest) (apply symbol=? s2 rest))))

  (define (exact-integer-sqrt k)
    (let ((s (exact (floor (sqrt k)))))
      (values s (- k (* s s)))))

  (define (make-list k . args)
    (let ((fill (if (null? args) #f (car args))))
      (let loop ((i 0) (acc '()))
        (if (= i k) acc
            (loop (+ i 1) (cons fill acc))))))

  (define (list-copy lst)
    (if (pair? lst)
        (cons (car lst) (list-copy (cdr lst)))
        lst))

  (define (list-set! lst k obj)
    (set-car! (list-tail lst k) obj))

  (define string-map
    (case-lambda
      ((f s)
       (let* ((len (string-length s))
              (result (make-string len)))
         (do ((i 0 (+ i 1)))
             ((= i len) result)
           (string-set! result i (f (string-ref s i))))))
      ((f s1 s2)
       (let* ((len (min (string-length s1) (string-length s2)))
              (result (make-string len)))
         (do ((i 0 (+ i 1)))
             ((= i len) result)
           (string-set! result i (f (string-ref s1 i) (string-ref s2 i))))))))

  (define string-for-each
    (case-lambda
      ((f s)
       (let ((len (string-length s)))
         (do ((i 0 (+ i 1)))
             ((= i len))
           (f (string-ref s i)))))
      ((f s1 s2)
       (let ((len (min (string-length s1) (string-length s2))))
         (do ((i 0 (+ i 1)))
             ((= i len))
           (f (string-ref s1 i) (string-ref s2 i)))))))

  (define r7rs:vector-copy
    (case-lambda
      ((v) (vector-copy v))      ;; Chez's built-in
      ((v start)
       (let* ((len (- (vector-length v) start))
              (result (make-vector len)))
         (do ((i 0 (+ i 1)))
             ((= i len) result)
           (vector-set! result i (vector-ref v (+ start i))))))
      ((v start end)
       (let* ((len (- end start))
              (result (make-vector len)))
         (do ((i 0 (+ i 1)))
             ((= i len) result)
           (vector-set! result i (vector-ref v (+ start i))))))))

  (define (vector-copy! to at from . args)
    (let* ((start (if (null? args) 0 (car args)))
           (end (if (or (null? args) (null? (cdr args)))
                    (vector-length from)
                    (cadr args)))
           (len (- end start)))
      (if (< at start)
          (do ((i 0 (+ i 1)))
              ((= i len))
            (vector-set! to (+ at i) (vector-ref from (+ start i))))
          (do ((i (- len 1) (- i 1)))
              ((< i 0))
            (vector-set! to (+ at i) (vector-ref from (+ start i)))))))

  (define (vector-append . vecs)
    (let* ((lengths (map vector-length vecs))
           (total (apply + lengths))
           (result (make-vector total)))
      (let loop ((vecs vecs) (pos 0))
        (if (null? vecs)
            result
            (let ((v (car vecs)))
              (do ((i 0 (+ i 1)))
                  ((= i (vector-length v)))
                (vector-set! result (+ pos i) (vector-ref v i)))
              (loop (cdr vecs) (+ pos (vector-length v))))))))

  (define (close-port port)
    (when (input-port? port) (close-input-port port))
    (when (output-port? port) (close-output-port port)))

  (define (features) (r7rs-features))

  ;; define-values macro
  (define-syntax define-values
    (syntax-rules ()
      ((_ () expr)
       (begin expr (void)))
      ((_ (id) expr)
       (define id (call-with-values (lambda () expr) (lambda (v) v))))
      ((_ (id0 id1 ...) expr)
       (begin
         (define id0 (void))
         (define id1 (void)) ...
         (call-with-values (lambda () expr)
           (lambda (v0 v1 ...)
             (set! id0 v0)
             (set! id1 v1) ...))))))

  ;; syntax-error
  (define-syntax syntax-error
    (lambda (x)
      (syntax-case x ()
        ((_ msg arg ...)
         (syntax-violation #f
           (apply string-append
             (datum msg)
             (map (lambda (a) (format " ~a" (datum a)))
                  (list (datum arg) ...)))
           x)))))

  ;; ... remaining implementations
)
```

#### 3.4 Simple Re-export Libraries

These libraries are thin wrappers that re-export subsets of Chez's bindings:

**`(scheme case-lambda)`** — trivial:
```scheme
(library (scheme case-lambda) (export case-lambda) (import (chezscheme)))
```

**`(scheme char)`** — character classification and case conversion:
```scheme
(library (scheme char)
  (export char-alphabetic? char-numeric? char-whitespace?
          char-upper-case? char-lower-case?
          char-upcase char-downcase char-foldcase
          char-ci=? char-ci<? char-ci>? char-ci<=? char-ci>=?
          string-upcase string-downcase string-foldcase
          string-ci=? string-ci<? string-ci>? string-ci<=? string-ci>=?
          digit-value)
  (import (chezscheme))
  ;; Only digit-value needs implementation
  (define (digit-value c)
    (let ((n (- (char->integer c) (char->integer #\0))))
      (if (<= 0 n 9) n #f))))
```

**`(scheme complex)`** — direct re-exports:
```scheme
(library (scheme complex)
  (export angle imag-part magnitude make-polar make-rectangular real-part)
  (import (chezscheme)))
```

**`(scheme cxr)`** — 24 cXXXXr procedures:
```scheme
(library (scheme cxr)
  (export caaar caadr cadar caddr cdaar cdadr cddar cdddr
          caaaar caaadr caadar caaddr cadaar cadadr caddar cadddr
          cdaaar cdaadr cdadar cdaddr cddaar cddadr cdddar cddddr)
  (import (chezscheme)))
```

**`(scheme eval)`**:
```scheme
(library (scheme eval)
  (export eval)
  (import (chezscheme))
  ;; R7RS environment is handled specially — may need adaptation
  ;; Chez eval works in interaction-environment by default
  (define r7rs:eval
    (case-lambda
      ((expr) (eval expr))
      ((expr env) (eval expr env)))))
```

Note: R7RS `environment` takes library names and returns an immutable environment.
Chez's `environment` does this already for R6RS library names. We need to map
`(scheme base)` etc. to our libraries.

**`(scheme file)`**:
```scheme
(library (scheme file)
  (export call-with-input-file call-with-output-file
          open-input-file open-output-file
          open-binary-input-file open-binary-output-file
          with-input-from-file with-output-to-file
          file-exists? delete-file)
  (import (chezscheme) (r7rs internal ports)))
```

**`(scheme inexact)`**:
```scheme
(library (scheme inexact)
  (export acos asin atan cos exp finite? infinite? log nan? sin sqrt tan)
  (import (chezscheme)))
```

**`(scheme read)`**, **`(scheme repl)`**, **`(scheme write)`** — similar thin wrappers.

#### 3.5 `(scheme lazy)` — Iterative Forcing

```scheme
(library (scheme lazy)
  (export delay delay-force force make-promise promise?)
  (import (chezscheme) (r7rs internal promises))
  (define-syntax delay
    (syntax-rules ()
      ((_ expr) (r7rs:delay (lambda () expr)))))
  (define-syntax delay-force
    (syntax-rules ()
      ((_ expr) (r7rs:delay-force (lambda () expr)))))
  (define force r7rs:force)
  (define promise? r7rs-promise?))
```

#### 3.6 `(scheme process-context)`

```scheme
(library (scheme process-context)
  (export command-line exit emergency-exit
          get-environment-variable get-environment-variables)
  (import (chezscheme))
  (define (get-environment-variable name) (getenv name))
  (define (get-environment-variables)
    ;; Chez doesn't have a direct API; use foreign-procedure or
    ;; iterate through /proc/self/environ on Linux
    (error 'get-environment-variables "not yet implemented"))
  (define command-line (lambda () (command-line-arguments)))
  (define (emergency-exit . args)
    (let ((status (if (null? args) 0 (car args))))
      (foreign-procedure "exit" (int) void)
      (#%$exit status))))
```

#### 3.7 `(scheme time)`

```scheme
(library (scheme time)
  (export current-second current-jiffy jiffies-per-second)
  (import (chezscheme))
  ;; current-second: TAI seconds since Unix epoch
  ;; Chez doesn't have a TAI clock; use time-utc->date and add leap seconds
  (define current-second
    (lambda ()
      (let ((t (current-time 'time-utc)))
        (+ (time-second t)
           (/ (time-nanosecond t) 1000000000)
           ;; TAI-UTC offset (as of 2017: 37 seconds)
           37))))
  ;; current-jiffy: monotonic nanosecond counter
  (define jiffies-per-second (lambda () 1000000000))
  (define current-jiffy
    (lambda ()
      (let ((t (current-time 'time-monotonic)))
        (+ (* (time-second t) 1000000000)
           (time-nanosecond t))))))
```

#### 3.8 `(scheme r5rs)` — R5RS Compatibility

Re-export the ~80 R5RS standard bindings. Most are directly available from Chez.
Key adaptation: R5RS `eval` takes an environment specifier (e.g.,
`(scheme-report-environment 5)`).

```scheme
(library (scheme r5rs)
  (export
    ;; All ~80 R5RS identifiers
    * + - / < <= = > >= abs acos and angle append apply asin
    assoc assq assv atan begin boolean? ... zero?
    eval interaction-environment
    null-environment scheme-report-environment)
  (import (chezscheme) (scheme base)))
```

### Phase 3: Module System (Weeks 4-6)

#### 3.9 `define-library` Macro

The most architecturally significant piece. `define-library` must translate to
R6RS `library` forms, handling:

- `(export ...)` — maps directly
- `(import ...)` — maps directly (modulo library name translation)
- `(begin ...)` — library body
- `(include "file.scm")` — textual inclusion
- `(include-ci "file.scm")` — case-folding inclusion
- `(include-library-declarations "file.scm")` — include declaration forms
- `(cond-expand ...)` — conditional declarations

**Approach: Source-to-source transformer**

Rather than implementing `define-library` as a Chez macro (which would fight
the R6RS library system), implement a **source transformer** that reads R7RS
files and emits R6RS `library` forms.

```scheme
;; Transformer: R7RS define-library → R6RS library
(define (transform-define-library form)
  ;; Input:  (define-library (name ...)
  ;;           (export e ...)
  ;;           (import i ...)
  ;;           (begin body ...)
  ;;           (include "file") ...)
  ;; Output: (library (name ...)
  ;;           (export e ...)
  ;;           (import i ...)
  ;;           body ...)
  ...)
```

**Alternative: `define-library` as syntax-case macro**

It IS possible to implement `define-library` as a `syntax-case` macro that
expands to `library`, since Chez allows macros at the top level that expand
to `library` forms. This is simpler but has caveats:

1. `include` must be resolvable at macro-expansion time (need access to file system)
2. `cond-expand` must have access to the feature list at expansion time
3. The macro must handle all declaration orderings

```scheme
(define-syntax define-library
  (lambda (x)
    (syntax-case x (export import begin include include-ci cond-expand)
      ((_ name decl ...)
       (let-values (((exports imports bodies)
                     (parse-library-declarations #'(decl ...))))
         #`(library name
             (export #,@exports)
             (import #,@imports)
             #,@bodies))))))
```

**Recommendation:** Start with the syntax-case macro approach for simplicity.
If limitations emerge (e.g., `include` path resolution), fall back to the
source transformer.

#### 3.10 `include` and `include-ci`

These read a file and splice its contents as if they were typed in place.

```scheme
(define-syntax include
  (lambda (x)
    (syntax-case x ()
      ((_ filename)
       (let ((fn (datum filename)))
         (with-input-from-file fn
           (lambda ()
             (let loop ((forms '()))
               (let ((form (read)))
                 (if (eof-object? form)
                     #`(begin #,@(reverse forms))
                     (loop (cons (datum->syntax #'filename form) forms))))))))))))
```

For `include-ci`, wrap with `(parameterize ((case-sensitive #f)) ...)` during read.

#### 3.11 `cond-expand`

Must work both as an expression and as a library declaration.

```scheme
(define-syntax cond-expand
  (syntax-rules (and or not else library)
    ((_ (else body ...))
     (begin body ...))
    ((_ ((and) body ...) rest ...)
     (begin body ...))
    ((_ ((and req1 req2 ...) body ...) rest ...)
     (cond-expand
       (req1 (cond-expand ((and req2 ...) body ...) rest ...))
       rest ...))
    ((_ ((or) body ...) rest ...)
     (cond-expand rest ...))
    ((_ ((or req1 req2 ...) body ...) rest ...)
     (cond-expand
       (req1 body ...)
       ((or req2 ...) body ...)
       rest ...))
    ((_ ((not req) body ...) rest ...)
     ;; This one requires compile-time feature detection
     ;; Cannot be done purely with syntax-rules
     ...)
    ((_ ((library (name ...)) body ...) rest ...)
     ;; Check if library exists
     ...)
    ((_ (feature-id body ...) rest ...)
     ;; Check if feature-id is in the features list
     ...)))
```

**Challenge:** Pure `syntax-rules` cannot perform feature tests at compile time.
This requires either:
1. A `syntax-case` implementation with compile-time evaluation, or
2. Pre-processing the `cond-expand` before macro expansion

**Recommendation:** Use `syntax-case` with `(eval ...)` at expand time to check features.

---

## 4. Key Design Decisions

### 4.1 `error` Procedure Incompatibility

R7RS: `(error message irritant ...)`
Chez/R6RS: `(error who message irritant ...)`

**Decision:** Create `r7rs:error` that constructs a Chez condition without `who`.
All R7RS code uses our `error`; existing Chez code continues to use Chez's `error`.
The error objects are standard Chez conditions, so `error-object?` etc. work
on both R7RS-raised and Chez-raised conditions.

### 4.2 `define-record-type` Incompatibility

R7RS uses SRFI-9 style; R6RS is completely different syntax. Both are named
`define-record-type`.

**Decision:** In `(scheme base)`, export our SRFI-9 version. Users importing from
`(chezscheme)` directly get the R6RS version. The implementations don't conflict
because each library controls its own namespace.

### 4.3 String Mutability

R7RS permits implementations to make strings immutable. Chez strings are mutable.

**Decision:** Keep strings mutable (R7RS allows this). Export `string-set!` and
`string-fill!` from `(scheme base)`. This is the path of least resistance and
most compatible.

### 4.4 Tail-Position Requirements

R7RS specifies the same tail positions as R6RS. Chez already handles these.

**Decision:** No changes needed. Verify with tail-call tests.

### 4.5 `eval` and `environment`

R7RS `environment` takes R7RS library names and returns an immutable environment
for `eval`. We need `(environment '(scheme base))` to work.

**Decision:** Wrap Chez's `environment` to map `(scheme ...)` library names.
Since our libraries are actual R6RS libraries installed in `lib/`, Chez's
`environment` should work directly once the library path is configured.

### 4.6 TAI vs UTC for `current-second`

R7RS specifies TAI seconds. Chez provides UTC.

**Decision:** Add the TAI-UTC offset (currently 37 seconds as of 2017; should
be updatable). Document this as an approximation. A fully correct implementation
would need a leap second table.

---

## 5. Testing Strategy

### 5.1 Test Sources

1. **Chibi Scheme's R7RS test suite** — the de facto conformance test
   - Adapted from the R7RS specification examples
   - Covers all 16 libraries
   - Must be adapted to run under our framework

2. **Per-library unit tests** — focused tests for each library, especially:
   - `bytevector-copy!` argument order (critical regression risk)
   - `define-record-type` SRFI-9 semantics
   - `delay-force` iterative forcing (stack depth test)
   - `cond-expand` feature detection
   - `include`/`include-ci` file resolution
   - `error-object?` on both R7RS and Chez-raised errors
   - `guard` re-raise semantics

3. **Cross-compatibility tests** — verify that R7RS code can import from Chez
   libraries and vice versa (interop with the chez-* ecosystem).

### 5.2 Test Runner

```scheme
;; tests/run-all.ss
(import (chezscheme))
(library-directories '("./lib" "."))

;; Load and run each test file
(for-each (lambda (test-file)
            (printf "Running ~a...~n" test-file)
            (load test-file))
          '("tests/base-test.ss"
            "tests/char-test.ss"
            "tests/lazy-test.ss"
            ;; ...
            ))
```

### 5.3 CI Integration

```makefile
test:
	scheme --libdirs lib tests/run-all.ss

test-r7rs:
	scheme --libdirs lib tests/r7rs-tests.ss
```

---

## 6. Build System

### 6.1 Makefile

```makefile
SCHEME = scheme
LIBDIR = lib
SCHEME_FLAGS = --libdirs $(LIBDIR)

# Pre-compile all libraries to .so files for faster loading
compile:
	$(SCHEME) $(SCHEME_FLAGS) --program compile-libs.ss

# Run the test suite
test:
	$(SCHEME) $(SCHEME_FLAGS) --program tests/run-all.ss

# Install to Chez's library path
install:
	cp -r $(LIBDIR)/scheme $(CHEZ_LIB)/
	cp -r $(LIBDIR)/r7rs $(CHEZ_LIB)/

clean:
	find $(LIBDIR) -name "*.so" -delete
```

### 6.2 No Compilation Required for Basic Use

Since these are pure Scheme libraries, they can be loaded directly by setting
`(library-directories)`. Pre-compilation to `.so` is optional but recommended
for performance.

---

## 7. Implementation Order (Dependency-Driven)

```
Phase 1: Internal support modules
  ├── (r7rs internal error-objects)
  ├── (r7rs internal promises)
  ├── (r7rs internal record-type)
  ├── (r7rs internal bytevector-compat)
  ├── (r7rs internal division)
  ├── (r7rs internal ports)
  ├── (r7rs internal write)
  └── (r7rs features)

Phase 2: Simple libraries (direct re-exports)
  ├── (scheme case-lambda)          ← trivial
  ├── (scheme complex)              ← trivial
  ├── (scheme cxr)                  ← trivial
  ├── (scheme inexact)              ← trivial
  ├── (scheme char)                 ← mostly re-export + digit-value
  ├── (scheme read)                 ← thin wrapper
  ├── (scheme repl)                 ← thin wrapper
  └── (scheme time)                 ← new implementations

Phase 3: Medium libraries
  ├── (scheme file)                 ← wrappers for binary file ports
  ├── (scheme write)                ← write-shared, write-simple
  ├── (scheme lazy)                 ← delay-force (depends on promises)
  ├── (scheme process-context)      ← env variables, exit
  ├── (scheme load)                 ← wrapper around Chez load
  └── (scheme eval)                 ← environment mapping

Phase 4: The big one
  └── (scheme base)                 ← depends on all internals

Phase 5: Compatibility
  └── (scheme r5rs)                 ← depends on (scheme base)

Phase 6: Module system
  ├── define-library macro/transformer
  ├── include / include-ci
  └── cond-expand
```

---

## 8. Known Challenges and Mitigations

### 8.1 `bytevector-copy!` Argument Order

**Risk:** High. This is the most dangerous incompatibility — same name, different
argument order. Getting it wrong causes silent data corruption.

**Mitigation:**
- Import Chez's `bytevector-copy!` under a different name internally
- Wrap with R7RS argument order
- Extensive unit tests covering edge cases (overlapping copies, empty ranges)
- Document prominently in README

### 8.2 `guard` Semantics

R7RS `guard` re-evaluates the guard test in the dynamic extent of the `guard`
form, not the raise. This is subtle and Chez's `guard` may or may not match.

**Mitigation:** Test Chez's `guard` behavior carefully. If it differs, implement
our own `guard` using `call/cc` and `with-exception-handler`.

### 8.3 `include` Path Resolution

`include` must resolve paths relative to the file containing the `include` form.

**Mitigation:** Use Chez's `source-file-descriptor` or `#%$source-file-descriptor`
to determine the including file's directory. Fall back to `(current-directory)`.

### 8.4 `cond-expand` at Library Declaration Level

`cond-expand` must work both as an expression and as a library declaration
(inside `define-library`). The expression-level version is a macro; the
declaration-level version must be handled by the `define-library` transformer.

**Mitigation:** Handle `cond-expand` specially in the `define-library` macro,
expanding it before processing other declarations.

### 8.5 Multiple Return Values

R7RS and R6RS handle multiple values the same way. No issues expected.

### 8.6 `map`/`for-each` on Unequal-Length Lists

R7RS specifies that `map` and `for-each` terminate when the shortest list
is exhausted. R6RS requires equal-length lists (error otherwise). Chez's
implementation may or may not handle this.

**Mitigation:** Test Chez's behavior. If it errors on unequal lengths, provide
our own `map`/`for-each` wrappers.

### 8.7 `get-environment-variables`

Chez doesn't provide a way to list all environment variables.

**Mitigation:** Use `foreign-procedure` to call C's `environ` variable, or
read `/proc/self/environ` on Linux. This is the one place where platform-specific
code may be needed.

---

## 9. Interoperability with chez-* Ecosystem

### 9.1 Goal

R7RS libraries should work seamlessly alongside existing chez-* packages.
A program should be able to:

```scheme
(import (scheme base)
        (scheme write)
        (chez-sqlite))  ;; existing chez-* package
```

### 9.2 Strategy

- Our `(scheme ...)` libraries are standard R6RS libraries, so they participate
  normally in Chez's library resolution
- No conflicts with `(chezscheme)` — different namespace
- The only potential conflict is if user code imports both `(scheme base)` and
  `(chezscheme)`, since both export `error`, `define-record-type`, etc. with
  different semantics. Document this: use `(except ...)` or `(only ...)` to
  resolve conflicts.

### 9.3 Migration Path

For users wanting to port R7RS code to Chez:
1. Add `chez-r7rs/lib` to library directories
2. Replace `define-library` with `library` (or use our transformer)
3. `(import (scheme base))` instead of R7RS-specific imports
4. Existing Chez-specific code continues to work unchanged

---

## 10. Future: R7RS-Large

R7RS-large (Red/Tangerine/etc. editions) adds many SRFIs. This project focuses
on R7RS-small only. R7RS-large libraries can be added incrementally as separate
packages, each implemented as an R6RS library in the same `lib/` tree:

- `(scheme list)` — SRFI 1
- `(scheme vector)` — SRFI 133
- `(scheme sort)` — SRFI 132
- `(scheme hash-table)` — SRFI 125
- `(scheme set)` — SRFI 113
- `(scheme charset)` — SRFI 14
- `(scheme generator)` — SRFI 158
- `(scheme text)` — SRFI 135
- etc.

Each would follow the same pattern: R6RS library wrapping Chez primitives
plus new implementations where needed.

---

## 11. References

- [R7RS-small specification](https://small.r7rs.org/attachment/r7rs.pdf)
- [R6RS specification](http://www.r6rs.org/)
- [Chez Scheme User's Guide](https://cisco.github.io/ChezScheme/csug9.5/)
- [SRFI-9: Defining Record Types](https://srfi.schemers.org/srfi-9/)
- [Chibi Scheme R7RS tests](https://github.com/ashinn/chibi-scheme/tree/master/tests)
- [akku-r7rs approach](https://weinholt.se/articles/r7rs-comes-to-akku/)
- [Implementing R7RS on R6RS (Kato 2014)](https://www.schemeworkshop.org/2014/papers/Kato2014.pdf)
- [gwatt/chez-r7rs](https://github.com/gwatt/chez-r7rs)
