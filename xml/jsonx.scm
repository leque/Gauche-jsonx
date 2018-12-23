;; Copyright (c) 2017 OOHASHI Daichi <dico.leque.comicron.gmail.com>

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

(define-module xml.jsonx
  (export jsonx-xmlns
          parse-json-to-jsonx parse-json-to-jsonx*
          parse-json-string-to-jsonx
          parse-jsonx
          jsonx-array-handler jsonx-object-handler jsonx-special-handler
          construct-jsonx
          )
  (use gauche.collection)
  (use gauche.parameter)
  (use gauche.sequence)
  (use srfi-1)
  (use srfi-13)
  (use srfi-14)
  (use rfc.json)
  (use sxml.ssax)
  (use sxml.tools))

(select-module xml.jsonx)

;; API: jsonx-xmlns : String
(define-constant jsonx-xmlns "http://www.ibm.com/xmlns/prod/2009/jsonx")

(define (jsonx name)
  (string->symbol (format "~A:~A" jsonx-xmlns name)))

(define (jsonx-element? sxml)
  (equal? (sxml:name->ns-id (sxml:element-name sxml))
          jsonx-xmlns))

(define-syntax define-jsonx
  (syntax-rules ()
    ((_ name sym)
     (define name
       (let ((sym (jsonx 'sym)))
         (lambda (s)
           `(,sym ,s)))))))

(define-syntax define-jsonx*
  (syntax-rules ()
    ((_ name sym)
     (define name
       (let ((sym (jsonx 'sym)))
         (lambda (xs)
           `(,sym ,@xs)))))))

(define-jsonx jsonx-string string)

(define-jsonx jsonx-number number)

(define-jsonx jsonx-boolean boolean)

(define-jsonx* jsonx-array array)

(define-jsonx* jsonx-object object)

(define jsonx-null
  (let ((sym (jsonx 'null)))
    (lambda ()
      `(,sym))))

(define (%->jsonx x)
  (cond ((string? x)
         (jsonx-string x))
        ((number? x)
         (jsonx-number (number->string x)))
        ((pair? x) x)
        (else (error "cannot convert to JSONx" x))))

(define (handle-json-array xs)
  (jsonx-array (map %->jsonx xs)))

(define (handle-json-object kvs)
  (jsonx-object
   (map (lambda (kv)
          (sxml:set-attr (%->jsonx (cdr kv))
                         `(name ,(car kv))))
        kvs)))

(define (handle-json-special x)
  (case x
    ((null)
     (jsonx-null))
    ((true false)
     (jsonx-boolean (symbol->string x)))
    (else
     (error "unknown json-special"))))

(define (handle-json-top x)
  `(*TOP* ,x))

(define (with-jsonx-handlers thunk)
  (parameterize ((json-array-handler handle-json-array)
                 (json-object-handler handle-json-object)
                 (json-special-handler handle-json-special))
    (thunk)))

;; API: parse-json-to-jsonx : InputPort -> SXML
(define (parse-json-to-jsonx port)
  (with-jsonx-handlers
   (lambda ()
     (handle-json-top (parse-json port)))))

;; API: parse-json-to-jsonx* : InputPort -> (Listof SXML)
(define (parse-json-to-jsonx* port)
  (with-jsonx-handlers
   (lambda ()
     (map handle-json-top (parse-json* port)))))

;; API: parse-json-string-to-jsonx : String -> SXML
(define (parse-json-string-to-jsonx str)
  (with-jsonx-handlers
   (lambda ()
     (handle-json-top (parse-json-string str)))))

;; API: jsonx-array-handler : Parameterof ((Listof Any) -> Any)
(define jsonx-array-handler (make-parameter list->vector))

;; API: jsonx-object-handler :
;;         Parameterof ((Listof (Pairof (String Any))) -> Any)
(define jsonx-object-handler (make-parameter identity))

;; API: jsonx-special-handler : Parameterof ((U 'true 'false 'null) -> Any)
(define jsonx-special-handler (make-parameter identity))

(define (string-whitespace? x)
  (and (string? x)
       (string-every char-set:whitespace x)))

(define (sxml-special? x)
  (and (pair? x)
       (memq (sxml:element-name x)
             '(*TOP* *PI* *COMMENT* *ENTITY* *NAMESPACES*) )
       #t))

;; API: parse-jsonx : SXML -> Any
(define (%parse-jsonx sxml)
  (define (sxml:text sxml)
    (string-concatenate (filter string? (sxml:content sxml))))
  (unless (jsonx-element? sxml)
    (error "not a JSONx element" sxml))
  (case (string->symbol (sxml:ncname sxml))
    ((null)
     ((jsonx-special-handler) 'null))
    ((boolean)
     ((jsonx-special-handler)
      (case (string->symbol (string-trim-both (sxml:text sxml)))
        ((true false) => values)
        (else (error "invalid boolean" sxml)))))
    ((string)
     (sxml:text sxml))
    ((number)
     (string->number (string-trim-both (sxml:text sxml))))
    ((array)
     ((jsonx-array-handler)
      (filter-map (lambda (x)
                    (and (not (string-whitespace? x))
                         (not (sxml-special? x))
                         (%parse-jsonx x)))
                  (sxml:content sxml))))
    ((object)
     ((jsonx-object-handler)
      (filter-map (lambda (x)
                    (and (not (string-whitespace? x))
                         (not (sxml-special? x))
                         (cons (sxml:attr x 'name)
                               (%parse-jsonx x))))
                  (sxml:content sxml))))
    (else
     (error "not a JSONx element" sxml))))

(define (parse-jsonx sxml)
  (%parse-jsonx (case (sxml:element-name sxml)
                  ((*TOP*)
                   (car (remove sxml-special? (sxml:content sxml))))
                  (else
                   sxml))))

(define (%construct-jsonx obj)
  (cond ((or (eq? obj 'true) (eq? obj #t))
         (jsonx-boolean "true"))
        ((or (eq? obj 'false) (eq? obj #f))
         (jsonx-boolean "false"))
        ((eq? obj 'null)
         (jsonx-null))
        ((string? obj)
         (jsonx-string obj))
        ((number? obj)
         (let ((n (cond ((or (not (real? obj))
                             (infinite? obj)
                             (nan? obj))
                         (error "cannot convert to JSONx" obj))
                        ((and (rational? obj) (not (integer? obj)))
                         (inexact obj))
                        (else obj))))
           (jsonx-number (number->string n))))
        ((or (pair? obj)
             (is-a? obj <dictionary>))
         (jsonx-object (map (lambda (kv)
                              (sxml:set-attr (%construct-jsonx (cdr kv))
                                             `(name ,(car kv))))
                            obj)))
        ((is-a? obj <sequence>)
         (jsonx-array (map %construct-jsonx obj)))
        (else
         (error "cannot convert to JSONx" obj))))

;; API: construct-jsonx : Any -> SXML
(define (construct-jsonx obj)
  (handle-json-top (%construct-jsonx obj)))
