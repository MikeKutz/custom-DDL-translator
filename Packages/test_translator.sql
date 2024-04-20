clear screen;
set serveroutput on;
-- DBA: grant create sql translation profile, create procedure to test_schema;
-- translate any sql
-- alter system flush shared_pool;


create table if not exists test_dual as select * from dual;

create or replace
package test_translator
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
end;
/

create or replace
package body test_translator
as
  /* Wrapper for DBMS_SQL_TRANSLATE */
	procedure translate_sql (
		sql_text        in clob,
		translated_text out clob
	) as begin
		case
    when sql_text = 'select dummy from test_dual' then
      translated_text := q'[select 'Y' smart from test_dual]';
		when sql_text like 'create say %' then
			-- translated_text := q'[create or replace procedure p as begin dbms_output.put_line( '�?�]' || substr( sql_text, 12 ) || q'[�?�' ); end;]';
			translated_text := q'[begin dbms_output.put_line( '�?�]' || substr( sql_text, 5 ) || q'[�?�' ); end;]';
		when sql_text like 'create sayp %' then
			translated_text := q'[create or replace procedure p as begin dbms_output.put_line( ' ? ]' || substr( sql_text, 5 ) || q'[ ? ' ); end;]';
    when sql_text like 'say %' then
			translated_text := q'[begin dbms_output.put_line( '�?�]' || substr( sql_text, 5 ) || q'[�?�' ); end;]';
		when sql_text like 'begin say  %' then
			translated_text := q'[begin dbms_output.put_line( '�?�]' || substr( sql_text, 5 ) || q'[�?�' ); end;]';
		else null;
    end case;
  end;

	procedure translate_error (
		error_code          in binary_integer,
		translated_code     out binary_integer,
		translated_sqlstate out varchar2
	) as begin
    null;
  end;
end;
/

BEGIN
    dbms_sql_translator.create_profile( profile_name => 'TEST_SQL');

	-- DBMS_SQL_TRANSLATOR.REGISTER_SQL_TRANSLATION( 'TEST_SQL', 'select dummy from test_dual', 	Q'[select 'Z' ood from dual]' );
-- dbms_sql_translator.set_attribute('HR_PROFILE', dbms_sql_translator.attr_translator, 'YOUR_OWN_PACKAGE');

  DBMS_SQL_TRANSLATOR.SET_ATTRIBUTE(
    profile_name     =>  'TEST_SQL', 
    attribute_name   =>  DBMS_SQL_TRANSLATOR.ATTR_TRANSLATOR, 
    attribute_value  =>  'cSQL.test_translator');

  DBMS_SQL_TRANSLATOR.SET_ATTRIBUTE(
    profile_name     =>  'TEST_SQL', 
    attribute_name   =>  DBMS_SQL_TRANSLATOR.ATTR_FOREIGN_SQL_SYNTAX, 
    attribute_value  =>  'FALSE');

end;
/

alter session set sql_translation_profile = TEST_SQL;
-- alter session set events = '10601 trace name context forever, level 32';

select dummy from test_dual;

create sayp hello world;

create say hello world;


-- CLEAN UP
BEGIN
    dbms_sql_translator.DROP_PROFILE( profile_name => 'TEST_SQL');
    dbms_output.put_line( 'Profile dropped' );
exception
	when others then null;
end;
/

drop package if exists test_translator;

drop procedure if exists p;

drop table if exists test_dual purge;

