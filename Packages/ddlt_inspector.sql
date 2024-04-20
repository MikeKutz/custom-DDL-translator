create or replace
package ddlt_inspector
  authid current_user
as
  /* use by Developers of new Parser_t */

  /* ensures `txt` picks the correct object */
  procedure fetch_object( txt in clob );

  /* fetch and parse DDL.
     output is JSON of parsed DDL
    */
  procedure parse_string( txt in clob );

  /* fetch,parse, and asserts DDL */
  procedure validate_ddl( txt in clob );

  /* builds all code then displays them

     null/zero `code_index` shows all
     out-of-bound `code_index` shows error
  */
  procedure build_clob( txt in clob, code_index in pls_integer default null );
end;
/
