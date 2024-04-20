clear screen
set serveroutput on

create or replace package test_translator
  authid current_user
as
  /* Wrapper for DBMS_SQL_TRANSLATE */
	procedure translate_sql (
		sql_text        in clob,
		translated_text out clob
	);

	procedure translate_error (
		error_code          in binary_integer,
		translated_code     out binary_integer,
		translated_sqlstate out varchar2
	);
end test_translator;
/

create or replace package body test_translator
as
  procedure execute_anonymous( txt clob )
  as
    pragma autonomous_transaction;
  begin
    execute immediate txt;
    commit;
  end;
  
  /* Wrapper for DBMS_SQL_TRANSLATE */
	procedure translate_sql (
		sql_text        in clob,
		translated_text out clob
	) as begin
		case
    when sql_text like 'create beer %' then
      execute_anonymous( 'create or replace procedure ".i.am.here" as begin null; end;' );
      translated_text := q'[create or replace procedure ".noop" as begin null; end;]';
		else null;
    end case;
  end translate_sql;

	procedure translate_error (
		error_code          in binary_integer,
		translated_code     out binary_integer,
		translated_sqlstate out varchar2
	) as begin
    null;
  end translate_error;
end test_translator;
/

BEGIN
    dbms_sql_translator.create_profile( profile_name => 'TEST_SQL');

  DBMS_SQL_TRANSLATOR.SET_ATTRIBUTE(
    profile_name     =>  'TEST_SQL', 
    attribute_name   =>  DBMS_SQL_TRANSLATOR.ATTR_TRANSLATOR, 
    attribute_value  =>  'cSQL.test_translator'); -- ADJUST OWNER NAME

end;
/

------------------------------------------------------
alter session set sql_translation_profile = TEST_SQL;
alter session set events = '10601 trace name context forever, level 32';

create beer garden;


-- CLEAN UP -------------------------------------------
BEGIN
    dbms_sql_translator.DROP_PROFILE( profile_name => 'TEST_SQL');
exception
  when others then
    dbms_output.put_line( 'Nobody home.' );
end;
/

drop package test_translator;

drop package if exists ".noop";
drop package if exists ".i.am.here";
