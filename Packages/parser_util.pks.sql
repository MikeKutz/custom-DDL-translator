create or replace
package parser_util
  authid current_user
as
  /*
    for processing custom SQL to actual SQL
    includes code generator too
  */
  
  subtype object_name_t is varchar2(128 byte); -- Domain MKLibrary.object_name_d and cSQL._todo_


  type matchrecognize_keys is table of object_name_t;
  
  type matchrecognize_define_expression_hash is table of clob index by object_name_t;

    general_error exception;
    PRAGMA EXCEPTION_INIT (general_error, -20700);

/******************************************************************************/
  /*
  * function removes comments  and double-spaces and chr(10)
  * it WILL interfere with quotes
  *
  * @param txt unclean command  line
  * @return cleeaneed command  line
  */
  function  normalize_code( txt in clob ) return clob; -- accessible by ( package cSQL.ut_??? )
  
  /*
  *  converts  a  CLEAN command line  into tokens to be proceessed
  *
  * XMLPath  = /cmd/token
  * 
  * @param txt CLEAN  command line
  * @return   parsed XML  tree of  tokens
  */
  function convert2tree( txt in clob ) return xmltype;
  
  function parse_xml_tokens( xml_tokens in xmltype) return cSQL.tokens_nt pipelined;

  /* convert PATTERN into list of unique keys */
  function pattern_to_definition_keys( txt in clob ) return matchrecognize_keys;

  /* builds the DEFINE clause of a MATCH_RECOGINZE statement
  *
  * 
  * @param pattern_txt        actual PATTERN clause
  * @param definition_clause  additional DEFINE clause elements
  * @return complete DEFINITION clause that meets the needs of the give PATTERN clause
  */
  function build_define_clause( pattern_txt in clob, definition_hash in matchrecognize_define_expression_hash) return clob;
  
  /* converts a hash of define into actual DEFINE clause
  *  no alterations are done 
  *
  *  @param def_hash hash of values to be converted
  *  @return text representing DEFINE clause of MATCH_RECOGNIZE
  */
  function define_hash_to_clause( def_hash in matchrecognize_define_expression_hash ) return clob;
  
  /* extracts the keys of a hash into an array
  *  The array is used for MULTISET operations
  *
  *  @param def_hash the hash value who's keys needed to be extracted
  *  @return array of key values
  */
  function keys_to_array( def_hash in matchrecognize_define_expression_hash ) return matchrecognize_keys;


  -- huh ??
  function build_dyna_mr( pattern_txt    in clob 
                         ,definition_txt in clob
                        ) return clob;

  /*
      function pattern_parser( pattern_txt in clob, custom_dev in mr_define_exp_hash ) return tokens_nt
      calls DBMS_SQL
      may not be fit for PIPELINED function
  */
  function pattern_parser( statement_txt in clob
                          ,pattern_txt   in clob
                          ,custom_dev    in matchrecognize_define_expression_hash --> rename
                          ,sql_txt       out clob
                          ,run_sql       boolean default true -- what does this do?
                        ) return cSQL.tokens_nt; -- ?? accessible by (package cSQL.ut_???, type cSQL.syntax_parser_t );

  /* TODO
  parsed_tokens_to_json (from RAS Objects)
  json_to_code (new)
  */
  /* converts parsed tokens into JSON data */
  function parsed_tokens_to_json( x cSQL.tokens_nt ) return JSON;
  
  /* Generates code based on a code template using syntax JSON as the runtime variables
    TODO: using JSON inside a teJSON.Engine_t
    
    NOTE: both Blueprint and JSON should have passed Assertions already
    NOTE: overall wrapper is "syntax_parser_t.generate_code return clob"
  */
  function generate_code_from_JSON( syntax_json JSON, code_template teJSON.Blueprint ) return clob;
end;
/
