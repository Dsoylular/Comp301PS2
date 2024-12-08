#lang eopl

;; interpreter for the LET language.  The \commentboxes are the
;; latex code for inserting the rules into the code in the book.
;; These are too complicated to put here, see the text, sorry.

(require "lang.rkt")
(require "data-structures.rkt")
(require "environments.rkt")

(provide value-of-program value-of)

;;;;;;;;;;;;;;;; the interpreter ;;;;;;;;;;;;;;;;

;; value-of-program : Program -> ExpVal
;; Page: 71
(define value-of-program 
  (lambda (pgm)
    (cases program pgm
      (a-program (exp1)
                 (value-of exp1 (init-env))))))

;; value-of : Exp * Env -> ExpVal
;; Page: 71
(define value-of
  (lambda (exp env)
    (cases expression exp      
      (const-exp (num) (num-val num))

      (var-exp (var) (apply-env env var))
      
      (op-exp (exp1 exp2 op)
              (let ((val1 (value-of exp1 env))
                    (val2 (value-of exp2 env)))
                (let ((num1 (expval->rational val1))
                      (num2 (expval->rational val2)))
                  (cond 
                    ((and (number? num1) (number? num2))
                      (num-val
                        (cond 
                          ((= op 1) (+ num1 num2))
                          ((= op 2) (* num1 num2))
                          ;; -----------------------
                          ;; INSERT YOUR CODE HERE 
                          ;; -----------------------
                          ((= op 3) (/ num1 num2))
                          ((= op 4) (- num1 num2))
                        )))
                    
                    ((and (number? num1) (not (number? num2)))
                      (rational-val
                        (let ((num2top (car num2))
                              (num2bot (cdr num2)))
                          (cond 
                            ((= op 1) (cons (+ (* num1 num2bot) num2top) num2bot))
                            ((= op 2) (cons (* num1 num2top) num2bot))
                            ;; -----------------------
                            ;; INSERT YOUR CODE HERE 
                            ;; -----------------------
                            ((= op 3) (cons (* num1 (cdr num2)) (car num2)))
                            ((= op 4) (cons (- (* num1 (cdr num2)) (car num2)) (cdr num2)))
                          ))))

                    ((and (number? num2) (not (number? num1)))
                      (rational-val
                        (let ((num1top (car num1))
                              (num1bot (cdr num1)))
                          (cond 
                            ((= op 1) (cons (+ (* num1bot num2) num1top) num1bot))
                            ((= op 2) (cons (* num1top num2) num1bot))
                            ;; -----------------------
                            ;; INSERT YOUR CODE HERE 
                            ;; -----------------------
                            ((= op 3) (cons (* num1bot (cdr num2)) (car num2)))
                            ((= op 4) (cons (- (* num1bot (cdr num2)) (car num2)) (cdr num2)))
                          ))))

                    (else
                      (rational-val
                        (let ((num1top (car num1))
                              (num1bot (cdr num1))
                              (num2top (car num2))
                              (num2bot (cdr num2)))
                          (cond 
                            ((= op 1) (cons (+ (* num1top num2bot) (* num1bot num2top)) (* num1bot num2bot)))
                            ((= op 2) (cons (* num1top num2top) (* num1bot num2bot)))
                            ;; -----------------------
                            ;; INSERT YOUR CODE HERE 
                            ;; -----------------------
                            ((= op 3) (cons (* num1top (cdr num2)) (* num1bot (car num2))))
                            ((= op 4) (cons (- (* num1top (cdr num2)) (* num1bot (car num2))) (* num1bot (cdr num2))))
                          ))))))))
      (zero?-exp (exp1)
                 (let ((val1 (value-of exp1 env)))
                   (let ((num1 (expval->rational val1)))
                     (if (number? num1)
                         (if (zero? num1)
                             (bool-val #t)
                             (bool-val #f))
                         ;; -----------------------
                         ;; INSERT YOUR CODE HERE 
                         ;; -----------------------
                         (if (and (pair? num1) (zero? (car num1)))
                             (bool-val #t)
                             (bool-val #f))
                         ;; -----------------------
                       ))))

      (let-exp (var exp1 body)       
               (let ((val1 (value-of exp1 env)))
                 (value-of body
                           (extend-env var val1 env))))

      ;; -----------------------
      ;; INSERT YOUR CODE HERE 
      ;; -----------------------

      (simpl-exp (input)
                  (let ((val1 (value-of input env)))
                    (let ((num1 (expval->rational val1)))
                      (cond ((= (car num1) (cdr num1))
                             (num-val 1))

                            ((and (= (cdr num1) (gcd (car num1) (cdr num1)))
                                  (not (= 1 (gcd (car num1) (cdr num1)))))
                             (rational-val (cons
                                            (/ (car num1) (gcd (car num1) (cdr num1)))
                                            (/ (cdr num1) (gcd (car num1) (cdr num1))))))

                            ((= (cdr num1) (gcd (car num1) (cdr num1)))
                             (num-val (/ (car num1) (cdr num1))))

                            (else (rational-val (cons
                                                 (/ (car num1) (gcd (car num1) (cdr num1)))
                                                 (/ (cdr num1) (gcd (car num1) (cdr num1)))))))
                      )))
      
      (list-exp ()
                (list-val '()))

      (cons-exp (exp1 exp2)
                (let ((val1 (value-of exp1 env))
                      (val2 (value-of exp2 env)))
                  (let ((num (expval->num val1))
                        (numlist (expval->list val2)))
                    (list-val (cons num numlist)))))

      (mul-exp (exp1)
               (let ((val1 (value-of exp1 env)))
                 (let ((numlist (expval->list val1)))
                   (num-val (multiply-numlist numlist))
                   )))

      (min-exp (exp1)
               (let ((val1 (value-of exp1 env)))
                 (let ((lst1 (expval->list val1)))
                   (if (null? lst1)
                       (num-val -1)
                       (num-val (min-help lst1 (car lst1)))
                       )
                   )))

       (if-elif-exp (exp11 exp12 exp21 exp22 exp3)
                   (let ((val11 (value-of exp11 env))
                         (val12 (value-of exp12 env))
                         (val21 (value-of exp21 env))
                         (val22 (value-of exp22 env))
                         (val3 (value-of exp3 env)))
                     (cond ((expval->bool val11)
                            val12)
                           ((expval->bool val21)
                            val22)
                           (else val3))
                     ))

      (rational-exp (num1 num2)
                    (let ((n1 (expval->num (value-of num1 env)))
                          (n2 (expval->num (value-of num2 env))))
                      (if (zero? n2)
                          (eopl:error 'rational-exp "Denominator cannot be zero")
                          (rational-val (cons n1 n2)))))
      )))

;;mul-exp helper
(define (multiply-numlist lst)
  (if (null? lst)
      0
      (* (car lst) (if (null? (cdr lst))
                                              1
                                              (multiply-numlist (cdr lst)))
                               )))
;; min-exp helper
(define min-help (lambda (lst currentmin)
                   (if (null? lst)
                       currentmin
                       (if (<= (car lst) currentmin)
                           (min-help (cdr lst) (car lst))
                           (min-help (cdr lst) currentmin))
                       )))


;; gcd helper
(define gcd (lambda (a b)
              (cond ((= 0 a)
                     b)
                    ((= 0 b)
                     a)
                    ((= a b)
                     a)
                    ((> a b)
                     (gcd (- a b) b))
                    (else
                     (gcd a (- b a))))))
