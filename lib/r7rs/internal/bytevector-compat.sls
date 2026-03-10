;;; (r7rs internal bytevector-compat) — bytevector-copy! argument order adaptation
;;;
;;; R7RS: (bytevector-copy! to at from [start [end]])   — destination first
;;; Chez: (bytevector-copy! src ss dst ds count)         — source first, explicit count
;;;
;;; R7RS: (bytevector-copy bv [start [end]])             — optional slice
;;; Chez: (bytevector-copy bv)                           — whole copy only

(library (r7rs internal bytevector-compat)
  (export r7rs:bytevector-copy! r7rs:bytevector-copy)
  (import (chezscheme))

  ;; Rename Chez's bytevector-copy! so we can refer to it inside our wrapper
  ;; without name collision.
  (define chez:bytevector-copy! bytevector-copy!)
  (define chez:bytevector-copy  bytevector-copy)

  ;; R7RS bytevector-copy! (to at from [start [end]])
  (define r7rs:bytevector-copy!
    (case-lambda
      ((to at from)
       ;; Copy all of from into to starting at position at
       (chez:bytevector-copy! from 0 to at (bytevector-length from)))
      ((to at from start)
       ;; Copy from[start..end-of-from] into to starting at at
       (let ((len (- (bytevector-length from) start)))
         (chez:bytevector-copy! from start to at len)))
      ((to at from start end)
       ;; Copy from[start..end) into to starting at at
       (chez:bytevector-copy! from start to at (- end start)))))

  ;; R7RS bytevector-copy (bv [start [end]])
  (define r7rs:bytevector-copy
    (case-lambda
      ((bv)
       (chez:bytevector-copy bv))
      ((bv start)
       (let* ((end (bytevector-length bv))
              (len (- end start))
              (result (make-bytevector len)))
         (chez:bytevector-copy! bv start result 0 len)
         result))
      ((bv start end)
       (let* ((len (- end start))
              (result (make-bytevector len)))
         (chez:bytevector-copy! bv start result 0 len)
         result))))
)
