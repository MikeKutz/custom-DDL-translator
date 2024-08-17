create or replace
package ddlt_translator
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
end;
/
