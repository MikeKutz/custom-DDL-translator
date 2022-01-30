set serveroutput on;
exec dbms_output.put_line( ddlt_ras_ut.sample_acl(1));
exec dbms_output.put_line( ddlt_ras_ut.generate_json( 1, 'acl' ));
exec dbms_output.put_line( ddlt_ras_ut.generate_code( 1, 'acl' ));

exec dbms_output.put_line( ddlt_ras_ut.sample_policy(1));
exec dbms_output.put_line( ddlt_ras_ut.generate_json( 1, 'policy' ));
exec dbms_output.put_line( ddlt_ras_ut.generate_code( 1, 'policy' ));

