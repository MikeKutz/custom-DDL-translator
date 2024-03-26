create or replace
package body ddlt_macros
as

  function decode_triplet( txt in varchar2 ) return CLOB
    sql_macro(table)
  as
  begin
    return q'[select "_obj".obj.first_name   first_name
                    ,"_obj".obj.middle_name  middle_name
                    ,"_obj".obj.last_name    last_name
                    ,"_obj".obj.parts
              from (select db_object_triplet(txt) obj) "_obj"]';
  end decode_triplet;
  
  function decode_triplet_clean( txt in varchar2 ) return CLOB
    sql_macro(table)
  as
  begin
    return q'[select cast(cSQL.ddlt_util.prepare_name_for_dd("_obj".obj.first_name) as varchar2(128))  first_name
                    ,cast(cSQL.ddlt_util.prepare_name_for_dd("_obj".obj.middle_name) as varchar2(128)) middle_name
                    ,cast(cSQL.ddlt_util.prepare_name_for_dd("_obj".obj.last_name) as varchar2(128))   last_name
                    ,cast(cSQL.ddlt_util.prepare_name_for_dd("_obj".obj.parts) as int)       parts
              from (select cSQL.db_object_triplet(txt) obj) "_obj"]';
  end decode_triplet_clean;
  /* asserts that a schema exists
  */
  function assert_schema( uname in varchar2 ) return clob
    sql_macro(table)
  as
  begin
    return q'[select username
              from all_users
              where (username) = (select first_name from cSQL.ddlt_macros.decode_triplet_clean(uname))]';
  end assert_schema;
  
end ddlt_macros;
/

