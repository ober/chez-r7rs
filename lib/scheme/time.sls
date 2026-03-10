;;; (scheme time) — R7RS §6.14
;;; current-second, current-jiffy, jiffies-per-second

(library (scheme time)
  (export current-second current-jiffy jiffies-per-second)
  (import (chezscheme))

  ;; current-second: TAI seconds since Unix epoch (as inexact real).
  ;; R7RS specifies TAI time. Chez provides UTC via SRFI-19.
  ;; As of 2017, TAI is UTC + 37 leap seconds. We hard-code this.
  ;; Note: this will be wrong when a new leap second is added.
  (define tai-utc-offset 37)

  (define (current-second)
    (let ((t (current-time 'time-utc)))
      (+ (time-second t)
         (/ (time-nanosecond t) 1000000000.0)
         tai-utc-offset)))

  ;; jiffies-per-second: we use nanoseconds as jiffies (10^9 per second).
  (define (jiffies-per-second) 1000000000)

  ;; current-jiffy: monotonic jiffy counter (nanoseconds since some epoch).
  (define (current-jiffy)
    (let ((t (current-time 'time-monotonic)))
      (+ (* (time-second t) 1000000000)
         (time-nanosecond t))))
)
