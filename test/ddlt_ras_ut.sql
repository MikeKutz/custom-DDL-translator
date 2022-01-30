create or replace
package ddlt_ras_ut
as
    function sample_security_class( n int default 1 ) return clob;
    function sample_acl( n int default 1 ) return clob;
    function sample_policy( n int default 1 ) return clob;
    function generate_code( n int default 1, ras_obj in varchar2 ) return clob;
    function generate_json( n int default 1, ras_obj in varchar2 ) return clob;

end;
/

create or replace
package body ddlt_ras_ut
as
    sample_acl_txt dbms_sql.clob_table := dbms_sql.clob_table(
     1 =>  q'[
create application acl hr_acl for security class hrpriv aces (
    hr_representive => ( insert,update,select,delete,view_salary ),
    auditor => ( select, view_salary ) ,
    assasin => ( poison, mdk, select, delete )
)]',
    2 => q'[
create application acl hr_2_acl aces (
    hr_representive => ( insert,update,select,delete,view_salary )
)]'
    );

    sample_policy_txt dbms_sql.clob_table := dbms_sql.clob_table(
    
     1 => q'[
create application policy hr_policy for (
    domain ( department_id = 60 ) acls( it_acl ),
    domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    foreign key ( empno, deptno ) references hr.employees ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns ( salary , pii )
)]'
);

    sample_security_class_txt dbms_sql.clob_table := dbms_sql.clob_table( );

    
    function sample_security_class( n int default 1 ) return clob
    as
    begin
        if sample_security_class_txt.exists( n ) then
            return sample_security_class_txt( n );
        end if;
        
        return null;
    end;
    
    function sample_acl( n int default 1 ) return clob
    as
    begin
        if sample_acl_txt.exists( n ) then
            return sample_acl_txt( n );
        end if;
        
        return null;
    end;
    
    function sample_policy( n int default 1 ) return clob
    as
    begin
        if sample_policy_txt.exists( n ) then
            return sample_policy_txt( n );
        end if;
        
        return null;
    end;
    
    function ras_factory( txt clob, ras_obj in varchar2 ) return ddlt_master_obj
    as
        ret ddlt_master_obj;
    begin
        case ras_obj
            when 'acl' then
                ret := new ddlt_ras_acl(txt);
            when 'policy' then
                ret := new ddlt_ras_policy(txt);
            when 'security' then
                ret := new ddlt_ras_security_class(txt);
            else
                raise ddlt_util.general_error;
        end case;
        
        return ret;
    end;
    
    function get_ddl(  n int default 1, ras_obj in varchar2 ) return clob
    as
        ret clob;
    begin
        case ras_obj
            when 'acl' then
                ret := sample_acl(n);
            when 'policy' then
                ret := sample_policy(n);
            when 'security' then
                ret := sample_security_class(n);
            else
                raise ddlt_util.general_error;
        end case;
        
        return ret;
    end;
    
    function generate_code( n int default 1, ras_obj in varchar2 ) return clob
    as
        txt clob;
        ras ddlt_master_obj;
    begin
        txt := get_ddl( n, ras_obj );
        ras := ras_factory( txt, ras_obj );
        
        return ras.generate_code;
    end;

    function generate_json( n int default 1, ras_obj in varchar2 ) return clob
    as
        txt clob;
        ras ddlt_master_obj;
    begin
        txt := get_ddl( n, ras_obj );
        ras := ras_factory( txt, ras_obj );
        ras.parse_create_command;

        return ras.parsed_code;
    end;

end;
/
