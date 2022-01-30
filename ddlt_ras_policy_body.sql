create or replace
type body ddlt_ras_policy
as
    constructor function ddlt_ras_policy( txt in clob ) return self as result
    as
    begin
       
        (self as ddlt_master_obj).init(txt);
        
        return;
    end;

    OVERRIDING member procedure parse_create_command
    as
    
        policy_info    ddlt_ras_const.policy_info_t;
        mal_domain     tokens_nt;
        mal_foreign    tokens_nt;
        mal_privilege  tokens_nt;
--        mal_domain     ddlt_util.match_all_list;
--        mal_foreign    ddlt_util.match_all_list;
--        mal_privilege  ddlt_util.match_all_list;
        
        n int;

    begin
        -- extract head
        select abc.policy_name
            into policy_info
        from table( self.tokens )
        MATCH_RECOGNIZE (
        order by rn
        measures
             o_policy_name.token as policy_name
        pattern ( w_create w_application w_policy o_policy_name w_for c_start_list
            (   ( w_domain c_start_list l_domain_clause+? c_end_list w_acls c_start_list l_acl_list (c_comma l_acl_list )* c_end_list c_eol ) |
                ( w_foreign w_key c_start_list l_source_column ( c_comma l_source_column)* c_end_list w_references o_target_schema_table
                    c_start_list l_target_column (c_comma l_target_column)* c_end_list ( w_where c_start_list l_where_clause+? c_end_list )? c_eol ) |
                ( w_privilege o_privilege_name w_protects c_start_list l_protected_col (c_comma l_protected_col )* c_end_list c_eol )
            )+
        )
        define
            w_create        as token = 'create',
            w_application    as token = 'application',
            w_policy        as token = 'policy',
            w_for          as token = 'for',
            w_domain       as token = 'domain',
            w_acls        as token = 'acls',
            w_foreign       as token = 'foreign',
            w_key          as token = 'key',
            w_where        as token = 'where',
            w_references    as token = 'references',
            o_policy_name          as 1=ddlt_util.always_true(1),
            o_target_schema_table  as 1=ddlt_util.always_true(2),
            l_domain_clause        as 1=ddlt_util.always_true(3), -- w_acls.token
            l_acl_list       as 1=ddlt_util.always_true(4),
            l_source_column  as 1=ddlt_util.always_true(5),
            l_target_column  as 1=ddlt_util.always_true(6),
            l_where_clause   as 1=ddlt_util.always_true(7),
            l_protected_col  as 1=ddlt_util.always_true(8),
            c_start_list     as token = '(',
            c_end_list       as token = ')',
            c_comma          as token = ',',
            c_eol            as token in ( ',', ')' )
        ) abc;
        
        delete from ddlt_tokens_temp;
        insert into ddlt_tokens_temp
        select *
        from table( self.tokens );
        
        select count(*) into n
        from ddlt_tokens_temp;
        
        -- extract domain
        select tokens_t(abc.mn, abc.mc, abc.rn , abc.token)
            bulk collect into mal_domain
        from ddlt_tokens_temp
        MATCH_RECOGNIZE (
        order by rn
        measures
             MATCH_NUMBER() as mn,
             CLASSIFIER() as mc
             all rows per match

--            1+ - match_number()   as mn,
--            1+ - classification() as match_class,
--            0  - o_policy_name as policy_name
--            1  - min(w_domain), agg( l_domain_clause ), agg( l_acl_list )
--            2  - min(w_foreign), agg( l_source_column ), min(o_target_schema_table), agg( l_target_column ), agg( l_where_clause )
--            3  - min(w_privilege), min(o_privilege_name), agg( l_protected_column )
        pattern ( 
            w_domain c_start_list l_domain_clause*? c_end_list w_acls c_start_list l_acl_list (c_comma l_acl_list )* c_end_list
            c_eol 
        )
        define
            w_domain         as token = 'domain',
            w_acls           as token = 'acls',
            l_domain_clause  as 1=ddlt_util.always_true(3), -- w_acls.token
            l_acl_list       as 1=ddlt_util.always_true(4),
            c_start_list     as token = '(',
            c_end_list       as token = ')',
            c_comma          as token = ',',
            c_eol            as token in ( ',', ')' )
        ) abc;
    
    -- extract privileges
        select tokens_t(abc.mn, abc.mc, abc.rn , abc.token)
            bulk collect into mal_privilege
        from ddlt_tokens_temp
        MATCH_RECOGNIZE (
        order by rn
        measures
             MATCH_NUMBER() as mn,
             CLASSIFIER() as mc
        all rows per match
        pattern (  w_privilege o_privilege_name w_protects w_columns c_start_list l_protected_col (c_comma l_protected_col )* c_end_list c_eol )
        define
            w_privilege      as token='privilage',
            w_protects       as token='protects',
            w_columns        as token='columns',
            
            o_privilege_name as 1=ddlt_util.always_true(10),
            l_protected_col  as 1=ddlt_util.always_true(8),
            c_start_list     as token = '(',
            c_end_list       as token = ')',
            c_comma          as token = ',',
            c_eol            as token in ( ',', ')' )
        ) abc;
        
        -- extract FK (NOTE assumes order)
         select tokens_t(abc.mn, abc.mc, abc.rn , abc.token)
            bulk collect into mal_foreign
        from ddlt_tokens_temp
        MATCH_RECOGNIZE (
        order by rn
        measures
             MATCH_NUMBER() as mn,
             CLASSIFIER() as mc
        all rows per match
        pattern ( w_foreign w_key c_start_list l_source_column ( c_comma l_source_column)* c_end_list w_references o_target_schema_table
                    c_start_list l_target_column (c_comma l_target_column)* c_end_list ( w_where c_start_list l_where_clause+? c_end_list )? c_eol )
        define
            w_foreign       as token = 'foreign',
            w_key          as token = 'key',
            w_references    as token = 'references',
            w_where        as token = 'where',
            o_target_schema_table  as 1=ddlt_util.always_true(2),
            l_source_column  as 1=ddlt_util.always_true(5),
            l_target_column  as 1=ddlt_util.always_true(6),
            l_where_clause   as 1=ddlt_util.always_true(7),
            c_start_list     as token = '(',
            c_end_list       as token = ')',
            c_comma          as token = ',',
            c_eol            as token in ( ',', ')' )
        ) abc;
       

        -- generate json
        with dom as (
            select json_object( 'type' value 'domain'
                        ,'domain_clause' value listagg(  decode(upper(match_class),upper('l_domain_clause'), token) )  within group ( order by rn )
                        ,'amatch_class' value json_arrayagg( decode(upper(match_class),upper('l_acl_list'), token) )
                    ) json_rule
            from table( mal_domain )
            group by match#
        ), priv as (
            select json_object( 'type' value 'privilege'
                        ,'privilege_name' value min( decode(upper(match_class),upper('o_privilege_name'), token) )
                        ,'column_names' value  json_arrayagg( decode(upper(match_class),upper('l_protected_col'), token) )
                    ) json_rule
            from table( mal_privilege )
            group by match#
        ), fk as (
            select json_object( 'type' value 'foreign'
                        ,'target_table' value min( decode(upper(match_class),upper('o_privilege_name'), token) )
                        ,'source_columns' value  json_arrayagg( decode(upper(match_class),upper('l_source_column'), token) order by  rn )
                        ,'target_column' value  json_arrayagg( decode(upper(match_class),upper('l_target_column'), token) order by rn )
                        ,'where_clause' value listagg(  decode(upper(match_class),upper('l_where_clause'), token) )  within group ( order by rn )
                    ) json_rule
            from table( mal_foreign )
            group by match#
        )
        select json_serialize(
                    json_object( 'policy_name' value policy_info.policy_name
                         ,'rules' value json_arrayagg( d.json_rule )
                    ) pretty )
            into self.parsed_code
        from (
            select json_rule from dom
            union all
            select json_rule from priv -- priv
            union all
            select json_rule from fk -- foreign
        ) d;
    end;
    
/******************************************************************************/

    OVERRIDING member procedure parse_alter_command
    as
    begin
        null;
    end;
    
/******************************************************************************/

    OVERRIDING member procedure parse_drop_command
    as
    begin
        null;
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_create_code return clob
    as
    begin
        return 'create policy';
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_alter_code return clob
    as
    begin
        return 'alter policy';
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_drop_code return clob
    as
    begin
        return 'drop policy';
    end;
    
/******************************************************************************/
$if false $then
/*
create application policy hr_policy for (
    domain ( 1 = 1 ) amatch_class ( hr_acl, auditor_acl ),
    foreign key ( empno, deptno ) references hr.employees ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns (salary,pii)
)
type match_all_info is record ( mn int, match_class varchar2(50), rn int, token  varchar2(50) );
type match_all_list is table of match_all_info;
mal match_all_list;
select mn, match_class, rn, token
    into mal
match_recgonize (
order by rn
measures
    1+ - match_number()   as mn,
    1+ - classification() as match_class,
    
    0  - o_policy_name as policy_name
    1  - min(w_domain), agg( l_domain_clause ), agg( l_acl_list )
    2  - min(w_foreign), agg( l_source_column ), min(o_target_schema_table), agg( l_target_column ), agg( l_where_clause )
    3  - min(w_privilege), min(o_privilege_name), agg( l_protected_column )
pattern ( w_create w_application w_policy o_policy_name w_for c_start_list
    (   ( w_domain c_start_list l_domain_clause+? c_end_list w_acls c_start_list l_acl_list (c_comma l_acl_list )* c_end_list c_eol ) |
        ( w_foreign w_key c_start_list l_source_column ( c_comma l_source_column)* c_end_list w_references o_target_schema_table
            c_start_list l_target_column (c_comma l_target_column)* c_end_list ( w_where c_start_list l_where_clause+? c_end_list )? c_eol ) |
        ( w_privilege o_privilege_name w_protects c_start_list l_sss c_end_list c_eol )
    )+
)
define
    w_create    as token = 'create',
    w_application    as token = 'application',
    w_policy    as token = 'policy',
    w_for    as token = 'for',
    w_domain    as token = 'domain',
    w_acls    as token = 'amatch_class',
    w_foreign    as token = 'foreign',
    w_key    as token = 'key',
    w_where    as token = 'where',
    w_references    as token = 'references',
    o_policy_name    as 1=ddlt_util.allways_true(1),
    o_target_schema_table  as 1=ddlt_util.allways_true(2),
    l_domain_clause  as next( l_domain_clause.token ) != 'amatch_class', -- w_acls.token
    l_acl_list       as 1=ddlt_util.allways_true(4),
    l_source_column  as 1=ddlt_util.allways_true(5),
    l_target_column  as 1=ddlt_util.allways_true(6),
    l_where_clause   as 1=ddlt_util.allways_true(7),
    l_protected_col  as 1=ddlt_util.allways_true(8),
    c_start_list  as token = '('
    c_end_list    as token = ')'
    c_comma       as token = ',',
    c_eol         as token in ( ',', ')' )
*/
$end
end;
/
