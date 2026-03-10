;;; (r7rs internal ports) — R7RS I/O port procedures
;;; Provides the R7RS names not already available in (chezscheme).
;;;
;;; Already in (chezscheme) and just re-exported:
;;;   binary-port?, textual-port?, close-port, flush-output-port
;;;   open-input-string, open-output-string, get-output-string
;;;
;;; New implementations:
;;;   input-port-open?, output-port-open?
;;;   open-input-bytevector, open-output-bytevector, get-output-bytevector
;;;   open-binary-input-file, open-binary-output-file
;;;   read-u8, peek-u8, u8-ready?, write-u8
;;;   read-bytevector, read-bytevector!, write-bytevector
;;;   read-line
;;;   r7rs:string-copy, r7rs:string-copy!
;;;   r7rs:flush-output-port (accepts optional port arg)

(library (r7rs internal ports)
  (export
    ;; Already in Chez (re-exported)
    binary-port? textual-port?
    open-input-string open-output-string get-output-string
    close-port
    ;; New implementations
    input-port-open? output-port-open?
    open-input-bytevector open-output-bytevector get-output-bytevector
    open-binary-input-file open-binary-output-file
    r7rs:flush-output-port
    read-u8 peek-u8 u8-ready? write-u8
    read-bytevector read-bytevector! write-bytevector
    read-line
    r7rs:string-copy r7rs:string-copy!)
  (import
    ;; Import flush-output-port under a private name so we can wrap it
    (rename (chezscheme) (flush-output-port chez:flush-output-port)))

  ;; --- Port state predicates (not in Chez) ---
  (define (input-port-open?  p) (and (input-port?  p) (not (port-closed? p))))
  (define (output-port-open? p) (and (output-port? p) (not (port-closed? p))))

  ;; --- Bytevector ports (not in Chez) ---
  (define (open-input-bytevector bv) (open-bytevector-input-port bv))

  (define bvout-extractors (make-eq-hashtable))

  (define (open-output-bytevector)
    (let-values (((port extractor) (open-bytevector-output-port)))
      (hashtable-set! bvout-extractors port extractor)
      port))

  (define (get-output-bytevector port)
    (let ((ext (hashtable-ref bvout-extractors port #f)))
      (if ext
          (ext)
          (error 'get-output-bytevector "not an R7RS bytevector output port" port))))

  ;; --- Binary file ports ---
  (define (open-binary-input-file  filename) (open-file-input-port  filename))
  (define (open-binary-output-file filename) (open-file-output-port filename))

  ;; --- flush-output-port with optional port arg ---
  ;; Chez's flush-output-port requires exactly one arg; R7RS makes it optional.
  (define (r7rs:flush-output-port . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (chez:flush-output-port port)))

  ;; --- Binary I/O (not in Chez's chezscheme top-level) ---
  (define (read-u8 . args)
    (let ((port (if (null? args) (current-input-port) (car args))))
      (get-u8 port)))

  (define (peek-u8 . args)
    (let ((port (if (null? args) (current-input-port) (car args))))
      (lookahead-u8 port)))

  ;; u8-ready?: R7RS asks if a byte is available without blocking.
  ;; Chez doesn't have byte-ready?; we use #t as a conservative approximation.
  (define (u8-ready? . args)
    #t)

  (define (write-u8 byte . args)
    (let ((port (if (null? args) (current-output-port) (car args))))
      (put-u8 port byte)))

  (define (read-bytevector k . args)
    (let ((port (if (null? args) (current-input-port) (car args))))
      (get-bytevector-n port k)))

  (define (read-bytevector! bv . args)
    (let* ((port  (if (null? args) (current-input-port) (car args)))
           (args2 (if (null? args) '() (cdr args)))
           (start (if (null? args2) 0 (car args2)))
           (args3 (if (null? args2) '() (cdr args2)))
           (end   (if (null? args3) (bytevector-length bv) (car args3))))
      (get-bytevector-n! port bv start (- end start))))

  (define (write-bytevector bv . args)
    (let* ((port  (if (null? args) (current-output-port) (car args)))
           (args2 (if (null? args) '() (cdr args)))
           (start (if (null? args2) 0 (car args2)))
           (args3 (if (null? args2) '() (cdr args2)))
           (end   (if (null? args3) (bytevector-length bv) (car args3))))
      (put-bytevector port bv start (- end start))))

  ;; --- read-line (not in Chez's top level) ---
  (define (read-line . args)
    (let ((port (if (null? args) (current-input-port) (car args))))
      (get-line port)))

  ;; --- String copy with optional range ---
  (define (r7rs:string-copy s . args)
    (let* ((start (if (null? args) 0 (car args)))
           (end   (if (or (null? args) (null? (cdr args)))
                      (string-length s) (cadr args))))
      (substring s start end)))

  (define (r7rs:string-copy! to at from . args)
    (let* ((start (if (null? args) 0 (car args)))
           (end   (if (or (null? args) (null? (cdr args)))
                      (string-length from) (cadr args)))
           (len   (- end start)))
      (do ((i 0 (+ i 1)))
          ((= i len))
        (string-set! to (+ at i) (string-ref from (+ start i))))))
)
