set serverout on;

declare
    txt clob :=  q'[
create application acl hr_acl for security class hrpriv aces (
    hr_representive => ( insert,update,select,delete,view_salary ),
    auditor => ( select, view_salary ) ,
    assasin => ( poison, mdk, select, delete )
)]';

    t ddlt_ras_acl;
begin
--     dbms_output.put_line( '/*');

    t :=  new ddlt_ras_acl(  txt );

--    t.parse_create_command; -- converts TXT to JSON -- needs to be automatic
--     dbms_output.put_line( t.parsed_code  );
--     
--     dbms_output.put_line( '*/');
--    dbms_output.put_line(  t.generate_create_code );

    dbms_output.put_line( t.generate_code );
end;
/

