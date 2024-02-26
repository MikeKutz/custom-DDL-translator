create or replace
type syntax_parser_t as object
(
  /**
    Object for translating and generating custom SQL statements
    
    - syntax_action - enum of 'grant','drop','alter' etc
    - syntax_group - groups various syntaxes together (eg `create application security_class` and `create application acl`
    - syntax_subgroup - specific type of object (DML `syntax_action` should use `table`)
    - matchrecognize_pattern - string representing the `pattern` clause of `match_recognize`
    - matchrecognize_define - Hash of `define` lines of `match_recognize`
    - code_template - teJSON Blueprint (templated) used to generate the code for this specific syntax
    - match_string - used for finding syntax in table within the `dbms_sql_transform` function
    - is_saved - identified if updated/new syntax has been saved (interactive editing)
    
  *  @headcom UDT for managing custom SQL syntaxes
  */
   syntax_action          varchar2(128 byte) 
  ,syntax_group           varchar2(128 byte) -- object_name_t
  ,syntax_subtype         varchar2(128 byte) -- object_name_t
  ,matchrecognize_pattern clob
  ,matchrecognize_define  MKLibrary.Hash_t
  ,code_template          teJSON.Blueprint
  ,is_saved               boolean
  ,match_string           varchar2(1000 char)
  
  /* constructs object based on requested triplet
   *  if available, loads the triplet from table
   *  
   *  calls init()
   *
   *  @param  act   value for syntax_action
   *  @param  grp   value for syntax_group
   *  @param  obj   value for syntax_subgroup
   */
  ,constructor function syntax_parser_t( self in out nocopy syntax_parser_t, act in varchar2, grp varchar2, obj varchar2) return self as result
  
  /*
   * primitive for initializing the object.
   * If the triplet exists in storage, loads that information
   * otherwise, the values are set to initial value;
   *
   * @param  act   value for syntax_action
   * @param  grp   value for syntax_group
   * @param  obj   value for syntax_subgroup
   */
  ,member procedure init( self in out nocopy syntax_parser_t, act in varchar2, grp in varchar2, obj in varchar2)
  
  /* clears all syntax & template related attributes
   *
   * TODO : should have no parameters
  */
  ,member procedure reset_syntax( self in out nocopy syntax_parser_t, act in varchar2, grp in varchar2, obj in varchar2)
  
  /* asserts that the triplets are well defined
   */
  ,member procedure assert_name(self in out nocopy syntax_parser_t )
  
  /* asserts that the match_recognize attributes are well defined */
  ,member procedure assert_matchrecognize(self in out nocopy syntax_parser_t )
  
  /* asserts that the code template (Blueprint) is well defined
   *
   * TODO : define JSON Schema
   * TODO : define teJSON.Blueprint_d domain
   */
  ,member procedure assert_template(self in out nocopy syntax_parser_t )
  
  /* asserts that the `match_string` is properly formatted 
   * TODO : verify implementation
   */
  ,member procedure assert_match_string(self in out nocopy syntax_parser_t )
  
  /* assert that this instance passes all individual assertions */
  ,member procedure assert(self in out nocopy syntax_parser_t ) -- needs to do full assert

  /* saves the `syntax_group` as a known dimension */
  ,member procedure add_group(self in out nocopy syntax_parser_t )
  
  /* deletes the current `syntax_group`. This removes all subgroup syntaxes */
  ,member procedure drop_group(self in out nocopy syntax_parser_t )
  
  /* saves the current syntax definition in persistent storage */
  ,member procedure upsert_syntax(self in out nocopy syntax_parser_t )
  
  /* removes the current syntax definition from persistent storage */
  ,member procedure delete_syntax(self in out nocopy syntax_parser_t )

  /* returns the raw `pattern` for `match_recognize`
   *
   * TODO : remove from type; part of `parser_util`
   */
  ,member function get_pattern(self in out nocopy syntax_parser_t ) return clob

  /* returns the hash of non-standard *variable_name*:*condition* lines
   * for `define` portion of `match_recognize`
   *
   * TODO : remove from type; part of `parser_util`
   */
  ,member function get_define(self in out nocopy syntax_parser_t )  return clob

  /* generates the full `select` ... is this needed?
   *
   * TODO : remove from type; part of `parser_util`
   */
  ,member function get_matchrecognize(self in out nocopy syntax_parser_t ) return clob
  
  /* updates the `match_string` value with the required pattern
   *
   * TODO : move to init()/reset() section
  */
  ,member procedure update_match_string(self in out nocopy syntax_parser_t )
  
  -- code generator procedures
  /* asserts that the SQL statement belongs to this syntax
   *
   * TODO : implement : create Domain
   * TODO : move to assertion section
   */
  ,member procedure assert_syntax( self in out nocopy syntax_parser_t, code clob)
  
  /* translate SQL Statement to parsed JSON based on currently loaded syntax
   *
   * TODO : remove from type; part of `parser_util`
   */
  ,member function transpile( self in out nocopy syntax_parser_t, code clob ) return JSON

  /* single wrapper interface to generate code from SQL statement using current syntax settings
   *
   * this should be called using `dbms_sql_transform`
   *
   * TODO : implement : assert, generate, return appropriate code (do_debug)
   */
);
/