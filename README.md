# Gauche-jsonx [![Build Status](https://travis-ci.org/leque/Gauche-jsonx.svg?branch=master)](https://travis-ci.org/leque/Gauche-jsonx)

A [JSONx](https://www.ibm.com/support/knowledgecenter/en/SS9H2Y_7.5.0/com.ibm.dp.doc/json_jsonx.html) ([spec draft](https://tools.ietf.org/html/draft-rsalz-jsonx-00)) utility for [Gauche](http://practical-scheme.net/gauche/index.html).

## Requirement

* [Gauche](http://practical-scheme.net/gauche/) 0.9.6 or later

## API
### Module: xml.jsonx

#### Constant: jsonx-xmlns

The XML Namespace URI for JSONx.

#### Procedure: parse-json-to-jsonx input-port

Reads and parses the JSON representation from input-port,
and returns the result as a JSONx SXML.

#### Procedure: parse-json-to-jsonx* input-port

Read JSON repeatedly from input-port until it reaches EOF,
and returns parsed results as a list of JSONx SXMLs.

#### Procedure: parse-json-string-to-jsonx str

Parses the JSON string, and returns the result as a JSONx SXML.

#### Procedure: parse-jsonx sxml

Parses a JSONx SXML into an S-expression.

JSONx datatypes are mapped to Scheme objects as in
[`parse-json`](http://practical-scheme.net/gauche/man/?l=en&p=parse-json)
procedure of `rfc.json` module.

#### Parameter: jsonx-array-handler
#### Parameter: jsonx-object-handler
#### Parameter: jsonx-special-handler

Analogous to
[`json-array-handler`](http://practical-scheme.net/gauche/man/?l=en&p=json-array-handler),
[`json-object-handler`](http://practical-scheme.net/gauche/man/?l=en&p=json-object-handler),
and [`json-special-handler`](http://practical-scheme.net/gauche/man/?l=en&p=json-special-handler)
in `rfc.json` module.

Used by `parse-jsonx` procedure.

#### Procedure: construct-jsonx obj

Creates JSONx SXML representation of Scheme object obj.

Scheme objects are mapped to JSONx as in
[`construct-json`](http://practical-scheme.net/gauche/man/?l=en&p=construct-json)
procedure of `rfc.json` module.

## Examples

```scheme
gosh> (use xml.jsonx)
gosh> (pprint (call-with-input-file "test/data/test.json" parse-json-to-jsonx))
(*TOP*
 (http://www.ibm.com/xmlns/prod/2009/jsonx:object
  (http://www.ibm.com/xmlns/prod/2009/jsonx:string (|@| (name "name"))
   "John Smith")
  (http://www.ibm.com/xmlns/prod/2009/jsonx:object
   (|@| (name "address"))
   (http://www.ibm.com/xmlns/prod/2009/jsonx:string
    (|@| (name "streetAddress")) "21 2nd Street")
   (http://www.ibm.com/xmlns/prod/2009/jsonx:string (|@| (name "city"))
    "New York")
   (http://www.ibm.com/xmlns/prod/2009/jsonx:string (|@| (name "state")) "NY")
   (http://www.ibm.com/xmlns/prod/2009/jsonx:number (|@| (name "postalCode"))
    "10021"))
  (http://www.ibm.com/xmlns/prod/2009/jsonx:array (|@| (name "phoneNumbers"))
   (http://www.ibm.com/xmlns/prod/2009/jsonx:string "212 555-1111")
   (http://www.ibm.com/xmlns/prod/2009/jsonx:string "212 555-2222"))
  (http://www.ibm.com/xmlns/prod/2009/jsonx:null (|@| (name "additionalInfo")))
  (http://www.ibm.com/xmlns/prod/2009/jsonx:boolean (|@| (name "remote"))
   "false")
  (http://www.ibm.com/xmlns/prod/2009/jsonx:number (|@| (name "height")) "62.4")
  (http://www.ibm.com/xmlns/prod/2009/jsonx:string (|@| (name "ficoScore"))
   "> 640")))
gosh> (pprint (construct-jsonx '#(42 #t null (("foo" . #f)))))
(*TOP*
 (http://www.ibm.com/xmlns/prod/2009/jsonx:array
  (http://www.ibm.com/xmlns/prod/2009/jsonx:number "42")
  (http://www.ibm.com/xmlns/prod/2009/jsonx:boolean "true")
  (http://www.ibm.com/xmlns/prod/2009/jsonx:null)
  (http://www.ibm.com/xmlns/prod/2009/jsonx:object
   (http://www.ibm.com/xmlns/prod/2009/jsonx:boolean (|@| (name "foo")) "false")
   )))
```

## License

MIT
