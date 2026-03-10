;;; (scheme file) — R7RS §6.13.1
;;; File system operations and file port procedures.

(library (scheme file)
  (export
    call-with-input-file call-with-output-file
    open-input-file open-output-file
    open-binary-input-file open-binary-output-file
    with-input-from-file with-output-to-file
    file-exists? delete-file)
  (import (chezscheme)
          (r7rs internal ports))

  ;; Most of these are direct re-exports from (chezscheme):
  ;; call-with-input-file, call-with-output-file, open-input-file,
  ;; open-output-file, with-input-from-file, with-output-to-file,
  ;; file-exists?, delete-file

  ;; open-binary-input-file, open-binary-output-file come from (r7rs internal ports)
)
