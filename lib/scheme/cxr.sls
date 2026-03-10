;;; (scheme cxr) — R7RS §6.4
;;; All 24 cXXXr and cXXXXr procedures; all in (chezscheme).

(library (scheme cxr)
  (export
    ;; 3-deep
    caaar caadr cadar caddr
    cdaar cdadr cddar cdddr
    ;; 4-deep
    caaaar caaadr caadar caaddr
    cadaar cadadr caddar cadddr
    cdaaar cdaadr cdadar cdaddr
    cddaar cddadr cdddar cddddr)
  (import (chezscheme)))
