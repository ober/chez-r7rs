# chez-r7rs

A complete R7RS-small implementation on top of ChezScheme's R6RS foundation.

## Design

Each of the 16 `(scheme ...)` standard libraries is implemented as an R6RS `library`
file in `lib/scheme/`. A set of internal support modules in `lib/r7rs/internal/` provide
the semantic adaptations needed where Chez and R7RS diverge.

**Key design decisions:**
- Zero modifications to ChezScheme's source tree
- Pure Scheme implementation (no C code, no FFI)
- Each R7RS library is a standalone `.sls` file loadable by Chez
- Compatible with existing `(chezscheme)` code in the same program

## Usage

Add the `lib/` directory to Chez's library search path:

```scheme
;; In a program or REPL:
(library-directories (cons "path/to/chez-r7rs/lib" (library-directories)))

;; Or from the command line:
scheme --libdirs path/to/chez-r7rs/lib
```

Then import R7RS libraries normally:

```scheme
(import (scheme base)
        (scheme write))

(display "Hello, R7RS!")
(newline)
```

## Libraries

| Library | Description | Status |
|---------|-------------|--------|
| `(scheme base)` | Core R7RS procedures and syntax | ✓ |
| `(scheme case-lambda)` | `case-lambda` | ✓ |
| `(scheme char)` | Character classification and conversion | ✓ |
| `(scheme complex)` | Complex number operations | ✓ |
| `(scheme cxr)` | cXXXr / cXXXXr procedures | ✓ |
| `(scheme eval)` | `eval` and `environment` | ✓ |
| `(scheme file)` | File I/O | ✓ |
| `(scheme inexact)` | Inexact arithmetic | ✓ |
| `(scheme lazy)` | Lazy evaluation with `delay-force` | ✓ |
| `(scheme load)` | `load` | ✓ |
| `(scheme process-context)` | `command-line`, `exit`, env vars | ✓ |
| `(scheme r5rs)` | R5RS compatibility | ✓ |
| `(scheme read)` | `read` | ✓ |
| `(scheme repl)` | `interaction-environment` | ✓ |
| `(scheme time)` | `current-second`, jiffies | ✓ |
| `(scheme write)` | `write`, `display`, `write-shared`, etc. | ✓ |

## Module System Support

```scheme
(import (r7rs define-library))  ;; define-library macro
(import (r7rs cond-expand))     ;; standalone cond-expand
(import (r7rs include))         ;; include / include-ci
```

## Important Compatibility Notes

### `error` — Different Signature

R7RS: `(error message irritant ...)`
Chez: `(error who message irritant ...)`

When importing `(scheme base)`, `error` has R7RS semantics (no `who` argument).

### `define-record-type` — Different Syntax

R7RS/SRFI-9: `(define-record-type <name> (<constructor> <field> ...) <pred> ...)`
R6RS/Chez: different syntax with `(fields ...)` declarations

`(scheme base)` exports the SRFI-9 version.

### `bytevector-copy!` — Reversed Argument Order

R7RS: `(bytevector-copy! to at from [start [end]])` — destination first
Chez: `(bytevector-copy! src ss dst ds count)` — source first

`(scheme base)` exports the R7RS version.

### Mixing with `(chezscheme)`

If you import both `(scheme base)` and `(chezscheme)`, use `except`/`only` to
resolve conflicts for `error`, `define-record-type`, and `bytevector-copy!`.

## Running Tests

```bash
make test
```

## License

Public domain / MIT (same as ChezScheme).
# chez-r7rs
