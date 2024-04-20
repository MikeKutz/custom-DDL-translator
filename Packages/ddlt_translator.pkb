create or replace
package body ddlt_translator
as
  procedure execute_annonymous( txt clob )
  as
    pragma autonomous_transaction;
  begin
    execute immediate txt;
    commit;
  end execute_annonymous;

	procedure translate_sql (  sql_text        in clob
                            ,translated_text out clob
                          )
  as
    obj  cSQL.syntax_parser_t;
    e    teJSON.Engine_t;
    h    MKLibrary.Hash_t;
    p    varchar2(100);
    parsed_code JSON;
    rendered_code  MKLibrary.CLOB_Array;
  BEGIN
    select value(x) into obj
    from cSQL.syntax_lists x
    where sql_text like x.match_string;

    -- convert sql_text to JSON
    parsed_code := obj.transpile( sql_text );

    -- validate JSON
    -- TODO: validate JSON
    obj.assert_parsed( parsed_code );

    CASE
      when parsed_code is null THEN
        RAISE_APPLICATION_ERROR(-20999, 'did not parse code (null tokens)');
      when obj.syntax_action  in ( 'create', 'alter', 'drop') then 
        rendered_code := obj.build_all_code( parsed_code );

        if rendered_code is null then raise no_data_found; end if;

        for i,snippet in pairs of rendered_code
        loop
          -- null;
          dbms_output.put_line( snippet );
          execute_annonymous( snippet );
        end loop;

        case obj.syntax_action
          when 'drop' then
            execute_annonymous( 'create or replace procedure ".c##temp" as begin null; end;' );
            translated_text := 'drop procedure if exists ".c##temp"';
          when 'alter' then
            execute_annonymous( 'create or replace procedure ".noop" as begin null; end;' );
            translated_text := 'alter procedure ".noop" compile';
          when 'create' then
            translated_text := 'create or replace procedure ".noop" as begin null; end;';
          else
            RAISE_APPLICATION_ERROR(-20998, 'logic error');
        end case;
      else
      -- dbms_output.put_line( json_serialize(j));
      -- render code
      translated_text := obj.build_code( parsed_code );
    end case;

    return; 

  EXCEPTION
    when no_data_found THEN
      -- default
      dbms_output.put_line('nodata found');
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

