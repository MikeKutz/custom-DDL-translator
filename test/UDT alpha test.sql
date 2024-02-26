clear screen;
set serveroutput on;
exec dbms_output.put_line('I am here');
declare
  s syntax_parser_t;
  n int;
begin
  s := new syntax_parser_t( 'create', 'test', 'unit1' );
  dbms_output.put_line( 'match = ' || s.match_string );
  dbms_output.put_line( 'condition = ' || case when s.is_saved then 'saved' else '---' end );
  
  s.add_group();
  s.upsert_syntax;

  s.matchrecognize_pattern := 'x_wing+';
  s.upsert_syntax;

  select count(*) into n
  from syntax_lists
  where code_template is null;
  
  dbms_output.put_line( 'count = ' || n );
  rollback;
exception
  when others then rollback; raise;
end;
/

