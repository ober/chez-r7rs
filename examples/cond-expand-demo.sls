;;; examples/cond-expand-demo.sls — Feature detection with cond-expand
;;;
;;; Run with:
;;;   scheme --libdirs lib --program examples/cond-expand-demo.sls

(import (scheme base)
        (scheme write)
        (r7rs cond-expand))

;; Basic feature detection
(display
  (cond-expand
    (r7rs     "Running on an R7RS implementation")
    (else     "Unknown implementation")))
(newline)

;; Detect Chez Scheme specifically
(display
  (cond-expand
    (chez-scheme "ChezScheme detected!")
    (else        "Not Chez")))
(newline)

;; Platform detection
(display
  (cond-expand
    (posix   "POSIX platform")
    (windows "Windows platform")
    (else    "Unknown platform")))
(newline)

;; Combined conditions
(display
  (cond-expand
    ((and r7rs chez-scheme) "R7RS on Chez — full-featured!")
    ((and r7rs (not chez-scheme)) "R7RS on another Scheme")
    (else "Something else")))
(newline)

;; Conditional code generation
(define platform-info
  (cond-expand
    (posix
     (string-append "POSIX/"
                    (cond-expand
                      (64bit "64-bit")
                      (32bit "32-bit")
                      (else  "unknown-bits"))))
    (windows "Windows")
    (else    "Unknown")))

(display (string-append "Platform: " platform-info))
(newline)
