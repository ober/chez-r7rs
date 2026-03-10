;;; (r7rs features) — R7RS feature identifier registry
;;; Returns the list of feature symbols for use with cond-expand.

(library (r7rs features)
  (export r7rs-features)
  (import (chezscheme))

  (define r7rs-features
    (filter (lambda (x) x)
      (list 'r7rs
            'exact-closed
            'exact-complex
            'ieee-float
            'ratios
            'full-unicode
            'chez-scheme
            ;; Platform detection via Chez machine-type
            (case (machine-type)
              ((ta6le ti3le a6le i3le arm64le arm32le
                a6fb  i3fb  a6ob  i3ob  a6nb   i3nb)
               'posix)
              ((ta6nt ti3nt a6nt i3nt)
               'windows)
              (else #f))
            ;; Word-size features (derived from machine-type since fixnum-width
            ;; in Chez is 61 on 64-bit, not exactly 64)
            (case (machine-type)
              ((ta6le ti3le a6le a6fb a6ob a6nb a6nt
                ta6osx a6osx arm64le arm64osx ta6nt)
               (string->symbol "64bit"))
              ((ti3le i3le i3fb i3ob i3nb i3nt i3osx)
               (string->symbol "32bit"))
              (else #f))
            ;; Endianness
            (if (eq? (native-endianness) 'little) 'little-endian 'big-endian))))
)
