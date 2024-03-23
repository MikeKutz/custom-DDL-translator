create or replace
package body ddlt_translator
as
	procedure translate_sql (  sql_text        in clob
                            ,translated_text out clob
                          )
  as
    obj  cSQL.syntax_parser_t;
    e    teJSON.Engine_t;
    h    MKLibrary.Hash_t;
    p    varchar2(100);
    parsed_code JSON;
  BEGIN
    select value(x) into obj
    from syntax_lists x
    where sql_text like x.match_string;

    IF lower(SQL_TEXT) like '%select * from t%' THEN
      translated_text := q'[select 'Y' smart]';
      return;
    end if;

    -- obj should have
      -- DML action
      -- group
      -- subgroup
      -- match_recognize patern
      -- match_recognize define
      -- JSON Template
      -- JSON Schema (not used)
      -- path for `exec`
    
    -- convert sql_text to JSON
    parsed_code := obj.transpile( sql_text );

    -- validate JSON
    -- TODO: validate JSON
    if parsed_code is null THEN
      RAISE_APPLICATION_ERROR(-20999, 'did not parse code (null tokens)');
    else
      -- dbms_output.put_line( json_serialize(j));
      -- render code
      translated_text := obj.build_code( parsed_code );
    end if;


  EXCEPTION
    when no_data_found THEN
      dbms_output.put_line( 'not RAS SQL');
      return;
    when too_many_rows THEN
      raise zero_divide;
  end translate_sql;

	procedure translate_error (  error_code          in binary_integer
                              ,translated_code     out binary_integer
                              ,translated_sqlstate out varchar2
	                          )
  as
  BEGIN
    -- no error code translation at this time
    null;
  end translate_error;
end;
/

