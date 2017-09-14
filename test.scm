;;;
;;; Test xml.jsonx
;;;

(use gauche.test)

(test-start "xml.jsonx")
(use xml.jsonx)
(test-module 'xml.jsonx)

(use rfc.json)
(use sxml.ssax)

(define (test-parse-json-equivalence file)
  (test* #"(parse-jsonx (parse-json-to-jsonx p)) = (parse-json p): ~file"
         (call-with-input-file file parse-json)
         (parse-jsonx (call-with-input-file file parse-json-to-jsonx))))

(test-parse-json-equivalence "test/data/test1.json")
(test-parse-json-equivalence "test/data/test2.json")

(define (test-construct-jsonx-equivalence file)
  (test* #"(construct-jsonx (parse-json p)) = (parse-json-to-jsonx p): ~file"
         (call-with-input-file file parse-json-to-jsonx)
         (construct-jsonx (call-with-input-file file parse-json))))

(test-construct-jsonx-equivalence "test/data/test1.json")
(test-construct-jsonx-equivalence "test/data/test2.json")

(test* "parse-jsonx + xml->jsonx"
       (call-with-input-file "test/data/test.json" parse-json)
       (parse-jsonx
        (call-with-input-file "test/data/test.xml" (cut ssax:xml->sxml <> '()))))

;; If you don't want `gosh' to exit with nonzero status even if
;; the test fails, pass #f to :exit-on-failure.
(test-end :exit-on-failure #t)
