;;; (scheme inexact) — R7RS §6.2.6
;;; Inexact arithmetic; all available directly from (chezscheme).

(library (scheme inexact)
  (export acos asin atan cos exp finite? infinite? log nan? sin sqrt tan)
  (import (chezscheme)))
