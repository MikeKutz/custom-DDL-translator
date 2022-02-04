create or replace package body ddlt_ras_ut
as
    sample_acl_txt dbms_sql.clob_table := dbms_sql.clob_table(
     1 =>  q'[
create application acl hr_acl for security class hrpriv aces (
    principal hr_representive privileges ( insert,update,select,delete,view_salary ),
    principal auditor privileges ( select, view_salary ) ,
    principal assasin privileges ( poison, mdk, select, delete )
)]',
    2 => q'[
create application acl hr_2_acl aces (
    hr_representive => ( insert,update,select,delete,view_salary )
)]'
    );

    sample_policy_txt dbms_sql.clob_table := dbms_sql.clob_table(

     1 => q'[
create application policy hr_policy for (
    rls domain ( department_id = 60 ) acls( it_acl )
)]',

     2 => q'[
create application policy hr_policy for (
    rls domain ( department_id = 60 ) acls( it_acl ),
    rls domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    rls domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl )
)]',
     3 => q'[
create application policy hr_policy for (
    foreign source_columns ( empno, deptno ) references table hr.employees target_columns ( employee_id, department_id ) where ( private = 1 ) 
)]',
     5 => q'[
create application policy hr_policy for (
    rls domain ( department_id = 60 ) acls( it_acl ),
    rls domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    rls domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    privilege view_salary protects columns ( salary , pii ),
    foreign source_columns ( empno, deptno ) references table hr.employees target_columns ( employee_id, department_id ) where ( private = 1 ) 
)]',
     4 => q'[
create application policy hr_policy for (
    privilege view_salary protects columns ( salary , pii )
)]',


     9 => q'[
create application policy hr_policy for (
    domain ( department_id = 60 ) acls( it_acl ),
    domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    foreign key ( empno, deptno ) references hr.employees ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns ( salary , pii )
)]'
);

    sample_security_class_txt dbms_sql.clob_table := dbms_sql.clob_table(
        1 => 'create application security_class hr_priv
                    under ( sys.dml, sys.ns_mod )
                    define privileges ( view_salary, ppi )'
    );


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
        p clob;
        s clob;
        tt tokens_nt;
        err_code int;
        
        a token_aggregator_obj := new token_aggregator_obj;
        sql_txt clob;
    begin
        case ras_obj
            when 'aclx' then
                s := sample_acl( n );
--                p := sample_utp( n );
            else
                dbms_output.put_line('object type "' || ras_obj || '" not known.');
                raise no_data_found;
        end case;
        
        tt := ddlt_util.pattern_parser(  s
                                        ,p
                                        ,ddlt_util.mr_define_exp_hash()
                                        ,sql_txt );
        
        delete from ddlt_matched_tokens_temp;
        insert into ddlt_matched_tokens_temp
        select * from table(tt);
        
        a := new token_aggregator_obj();
        for t in (select * from table(tt) order by rn)
        loop
            null;
            err_code := a.iterate_step( tokens_t(t.match#, t.match_class, t.rn, t.token));
        end loop;
        dbms_output.put_line( 'RAS Objet  ="' || ras_obj || '"' );
        dbms_output.put_line( 'statement  ="' || s || '"' );
        dbms_output.put_line( 'pattern    ="' || p || '"' );
        dbms_output.put_line( 'JSON result=' || a.json_txt);
        dbms_output.put_line( '---------------------------' );
        
        return 'TODO';
    end;

    function generate_json( n int default 1, ras_obj in varchar2 ) return clob
    as
    begin
        return 'TODO';
    end;


end;
/
