# custom DDL translator
 Frame work for creating parsers for custom DDL statements.
 
# Components

## Main Components

- Package DDLT_UTIL
- Type TOKEN_AGGREGATOR_OBJ

## Supporting Objects

Type | Name | Purpose
-----|------|--------
Table | TOKEN_AGGREGATORS | Stores objects to be used via `REF()` within `TOKEN_AGGREGATOR_OBJ` These should be deleted when done
Sequence | TOKEN_AGGREGATOR_SEQ | Sequence for the PK of `TOKEN_AGGREGATORS`
Temp Table | DDLT_TOKENS_TEMP | Mostly used for overcoming an Ora-600. Good for debugging.
Temp Table | DDLT_MATCHED_TOKENS_TEMP | Good for debugging

## Additional Objects

Type | Name | Purpose
-----|------|--------
Package | DDLT_UT | Package used for Unit Testing
Package | DDLT_RAS | Planned package for developing RAS objects

# Usage

1. Send statement, pattern, and custom `DEFINE` components through `DDLT_UTIL.pattern_parser()`
2. Loop through resulting Matched Token through `TOKEN_AGGREATOR_OBJ.iterate_step()`
3. Build code from resulting JSON (out-of-scope for this project)

Example code

```sql
-- see DDLT_UT body (for now)
```

# Pattern Development

## Definitions

All Match Recognize tokens discovered in the given Pattern will be in the `DEFINE` clause.

Priority of Expression assignment to Match Recognize tokens
1. Custom Definition
1. Common Definition
1. Generic  `1=DDLT_UTIL.always_true(i)`

These definitions are defined in the Associative Array (`DDLT_UTIL.mr_define_exp_hash`).

The Common Definitions are used to control the operational state of the `TOKEN_AGGREGATOR_OBJ`.

These are:

Token | Value | Purpose
------|-------|-------
c_start_list | `(` | Start a List
c_end_list | `)` | End a List
c_comma  | `,` | Seperator of elements in a List
c_start_exp | `(` | Start an Expression
c_end_exp | `)` | End an Expression
c_start_obj | `(` | Start a child JSON object
c_end_obj   | `)` | End a child JSON object
c_start_obj_array | `(` | Start an array of JSON objects
c_end_obj_array | `)` | End an arraay of JSON object
c_obj_comma | `,` | Separator for JSON object
n_* | - | These become the JSON key of the next `JSON_ELEMENT` when the `JSON_ELEMENT` is complete
o_* | - | These are the value. `j.put( n_key, o_val )`
l_* | - | These are how List items are actually generated (in this version)
e_* | - | These are how Expressions are actually generated (in this version)

See `DDLT_UT` package for examples and usage.

# Examples

## n_ o_
(Run as `TEST# =>  1`)

Pattern

`(n_key o_val)+`

Statement

`key_1 val_1 key_2 val_2 key_3 val_3`

JSON result

`{"key_1":"val_1","key_2":"val_2","key_3":"val_3"}`

## List
(Run as `TEST# => 2`)

pattern

`(n_key c_start_list l_item (c_comma l_item)* c_end_list)+`

statement

`list_1 ( a, b, c, d ) list_2 ( 1, 2, 4, 4)`

JSON result

`{"list_1":["a","b","c","d"],"list_2":["1","2","4","4"]}`

## Expressions
(Run as `TEST# => 4`)

pattern
`(n_key c_start_exp e_tok+? c_end_exp)*`

`where ( 1 =1 ) andalso ( ablkd = fffff )`

JSON result= `{}`

**ERROR** should be `{"where":"1 =1","andalso":"fffff"}`

## Creating a JSON Child
(Run as `TEST# =>  5`)

pattern

`(n_key c_start_obj n_key o_val c_end_obj)+`

statement

`sub1 ( key1 val1 )`

JSON result

`{"sub1":{"key1":"val1"}}`

## RAS ACL
(Run as `TEST# => 10`)

pattern
```
w_ras n_acl o_acl_name n_ace_list c_start_obj_array
  (n_principal o_principal_name n_privileges c_start_list l_priv (c_comma l_priv)*  c_end_list
(c_obj_comma|c_end_obj_array))+
```

statement

`ras acl hr_acl aces ( principal hr_representive privileges ( insert , update, select, delete, show_salary ) )`

JSON result

`{"acl":"hr_acl","aces":[{"principal":"hr_representive","privileges":["insert","update","select","delete","show_salary"]}]}`

## Boolean Flags (`x_`))
(Run as `TEST#   8`)

pattern

`x_icecream x_witch x_sex x_age`

statement

`yes no maybe idontknow`

JSON result

`{"ICECREAM":"yes","WITCH":"no","SEX":"maybe","AGE":"idontknow"}`

## Test 3
(Run as `TEST# => 3`)

statement

`key_1 val_1 list_1 (a,b,c,d)`

pattern

`(n_key o_val) (n_key c_start_list l_item (c_comma l_item)* c_end_list)`

JSON result

`{"key_1":"val_1","list_1":["a","b","c","d"]}`

## Test 6
(Run as `TEST# => 6`)

pattern

`(n_key c_start_obj n_key o_val c_end_obj)+`

statement 

`sub1 ( key1 val1 ) sub2 (key2 val2)`

JSON result

`{"sub1":{"key1":"val1"},"sub2":{"key2":"val2"}}`

## Test 7
(Run as `TEST#   7`)

pattern

`n_one c_start_obj n_two c_start_list l_item (c_comma l_item)* c_end_list
            n_three o_three n_exp c_start_exp e_tok+? c_end_exp c_end_obj`

statement

`sub1 ( arr-1 ( a, b, c, d ) key1 val1 where ( 1 =1 ) )`

JSON result=`{}`

## Test 9
(Run as `TEST#   9`)

pattern

`n_phrases c_start_obj_array
                                ( x_verb x_person x_quote? (c_obj_comma|c_end_obj_array))+`

statement

`blight ( hello world, good-day to-you, kill all-humans Bender )"`

JSON result

`{"blight":[{"VERB":"hello","PERSON":"world"},{"VERB":"good-day","PERSON":"to-you"},{"VERB":"kill","PERSON":"all-humans","QUOTE":"Bender"}]}`
