set serverout on;

declare
    txt clob :=  q'[
create application policy hr_policy for (
    domain ( department_id = 60 ) acls( it_acl ),
    domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    foreign key ( empno, deptno ) references hr.employees ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns ( salary , pii )
)

)]';

    t ddlt_ras_policy;
begin

    t :=  new ddlt_ras_policy( txt );
--    t :=  new ddlt_ras_policy( null, null, txt, null, null );
--    t.parse_and_store_tokens;
    dbms_output.put_line('/*' );

    for i in 1 .. t.tokens.count
    loop
        dbms_output.put( t.tokens(i).token || ' ' );
    end loop;
--    t.parse_command_and_object;
    dbms_output.put_line('--' );


    t.parse_create_command;
    
    dbms_output.put_line( t.parsed_code );

    dbms_output.put_line('*/' );
    
--    dbms_output.put_line(  t.generate_create_code );

--    dbms_output.put_line( t.generate_code );

--    dbms_output.put_line( '/*');
--    dbms_output.put_line( t.parsed_code  );
--    dbms_output.put_line( '*/');

end;
/

