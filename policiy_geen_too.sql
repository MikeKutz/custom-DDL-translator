set serveroutput on;

declare
    txt  clob := policy_generator.json_text;
    procedure new_acl_entry( acl varchar2 )
    as
    begin
        dbms_output.put_line( 'acls.extend(1); acls(acls.last) := ''' || acl || ''';' );
    end;
    
    procedure new_domain_entry( domain_clause varchar2 )
    as
        ret clob;
    begin
        ret := 'dom.extend(1);
dom( dom.last ) := xs$something( realm => q''{' || domain_clause || '}''
                        acls => acls );
';
        dbms_output.put_line( ret );
    end;
    
    procedure clean_acls
    as
    begin
        dbms_output.put_line( 'acls := empty_acls;'  );
    end;
    
begin
    clean_acls;
    for rec in policy_generator.all_domains( txt )
    loop
        new_acl_entry( rec.acl );
        if rec.acl_# = 1 then
            new_domain_entry( rec.domain_clause );
            clean_acls;
        end if;
    end loop;
    
    dbms_output.put_line( 'xs_policy.generate_policy( policy_name => ''' || policy_generator.get_policy_name( txt )  || ''',
            doms => doms, acls  => acls );' );
end;
/

