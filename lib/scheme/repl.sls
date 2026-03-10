;;; (scheme repl) — R7RS §6.12
;;; REPL support: interaction-environment.

(library (scheme repl)
  (export interaction-environment)
  (import (chezscheme))

  ;; Chez's interaction-environment is the top-level environment.
  ;; R7RS: (interaction-environment) returns a mutable environment.
  ;; Chez's interaction-environment is a procedure with no args → environment.
)
