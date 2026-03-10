;;; (scheme read) — R7RS §6.13.2
;;; The read procedure; Chez's read is compatible with R7RS.

(library (scheme read)
  (export read)
  (import (chezscheme))

  ;; Chez's read is compatible with R7RS (handles #t, #f, vectors, etc.)
  ;; Re-export with optional port argument already supported.
)
