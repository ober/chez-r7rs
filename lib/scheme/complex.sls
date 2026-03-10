;;; (scheme complex) — R7RS §6.2.6
;;; Complex number operations; all available directly from (chezscheme).

(library (scheme complex)
  (export angle imag-part magnitude make-polar make-rectangular real-part)
  (import (chezscheme)))
