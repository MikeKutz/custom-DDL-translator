create or replace
package ddlt_macros
as
  /* DDLT sub-utility: concentration of all SQL_macros

    @headcom
  */

  /* used for decode
    cleans names for DD
  */
  function decode_triplet( txt in varchar2 ) return CLOB
    sql_macro(table);

  /* used for decode
    cleans names for DD
  */
  function decode_triplet_clean( txt in varchar2 ) return CLOB
    sql_macro(table);
    
  /* asserts that a schema exists
     quote mixed case
  */
  function assert_schema( uname in varchar2 ) return clob
    sql_macro(table);


  /* asserts that a package exists
     quote mixed case
    
    should have Schema. adjust for Package.Procedure prior to call
  */
  function assert_object( uname in varchar2, otype in varchar2) return clob
    sql_macro(table);

end ddlt_macros;
/
