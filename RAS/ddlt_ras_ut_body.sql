create or replace package body ddlt_ras_ut
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

    sample_ut_txt  dbms_sql.clob_table := dbms_sql.clob_table(
    1 => 'key_1 val_1 key_2 val_2 key_3 val_3',        -- multiple key-values
    2 => 'list_1 ( a, b, c, d ) list_2 ( 1, 2, 4, 4)', -- multiple lists
    3 => 'key_1 val_1 list_1 (a,b,c,d)',                -- mix key-val + list
    4 => 'where ( 1 =1 ) andalso ( ablkd = fffff )',    -- multiple expressions
    5 => 'sub1 ( key1 val1 )',
    6 => 'sub1 ( key1 val1 ) sub2 (key2 val2)',
    7 => 'sub1 ( arr-1 ( a, b, c, d ) key1 val1 where ( 1 =1 ) )',
    8 => 'yes no maybe idontknow',
    9 => 'blight ( hello world, good-day to-you, kill all-humans Bender )',
    10=> 'ras acl hr_acl aces ( principal hr_representive privileges ( insert , update, select, delete, show_salary ) )'
    
    );

    sample_ut_pt  dbms_sql.clob_table := dbms_sql.clob_table(
    1 => '(n_key o_val)+',
    2 => ' (n_key c_start_list l_item (c_comma l_item)* c_end_list)+',
    3 => '(n_key o_val)
                              (n_key c_start_list l_item (c_comma l_item)* c_end_list)',
    4 => '(n_key c_start_exp e_tok+? c_end_exp)*',
    5 => '(n_key c_start_obj n_key o_val c_end_obj)+',
    6 => '(n_key c_start_obj n_key o_val c_end_obj)+',
    7 => 'n_one c_start_obj n_two c_start_list l_item (c_comma l_item)* c_end_list
            n_three o_three n_exp c_start_exp e_tok+? c_end_exp c_end_obj',
    8 => 'x_icecream x_witch x_sex x_age',
    9 => 'n_phrases c_start_obj_array
                                ( x_verb x_person x_quote? (c_obj_comma|c_end_obj_array))+',
    10=> 'w_ras n_acl o_acl_name n_ace_list c_start_obj_array
            (n_principal o_principal_name n_privileges c_start_list l_priv (c_comma l_priv)*  c_end_list
        (c_obj_comma|c_end_obj_array))+'
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
    
    function sample_ut( n int default 1 ) return clob
    as
    begin
        if sample_ut_txt.exists( n ) then
            return sample_ut_txt( n );
        end if;

        return null;
    end;
    
    function sample_utp( n int default 1 ) return clob
    as
    begin
        if sample_ut_pt.exists( n ) then
            return sample_ut_pt( n );
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
    begin

        return 'TODO';
    end;

    function generate_json( n int default 1, ras_obj in varchar2 ) return clob
    as
    begin
        return 'TODO';
    end;


end;
/
