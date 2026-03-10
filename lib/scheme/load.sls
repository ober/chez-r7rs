;;; (scheme load) — R7RS §6.13.4
;;; The load procedure.

(library (scheme load)
  (export load)
  (import (rename (chezscheme) (load chez:load)))

  ;; R7RS load: (load filename [environment])
  ;; Chez's load doesn't take an environment argument; we ignore it.
  (define (load filename . args)
    (chez:load filename))
)
