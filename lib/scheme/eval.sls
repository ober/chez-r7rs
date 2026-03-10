;;; (scheme eval) — R7RS §6.12
;;; eval and environment procedures.

(library (scheme eval)
  (export eval environment)
  (import (rename (chezscheme) (eval chez:eval) (environment chez:environment)))

  ;; R7RS environment: (environment list ...) where each list is a library name
  ;; e.g. (environment '(scheme base) '(scheme write))
  ;; Chez's (environment lib ...) already does this for R6RS library names.
  ;; Our (scheme ...) libraries are real R6RS libraries, so this works directly.
  (define (environment . lib-names)
    (apply chez:environment lib-names))

  ;; R7RS eval: (eval expr environment)
  ;; Chez's eval: (eval expr environment) — same signature
  (define (eval expr env)
    (chez:eval expr env))
)
