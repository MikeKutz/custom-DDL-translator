create or replace
package  app_policy_proceesssor
as
    type policy_meta is record ( policy_name varchar2(50),bypass_clause  varchar2(50) );
    type domain_clause_t is record  ( mn int,  domain_priv varchar2(50), stat_dyn varchar2(50), code_txt varchar2(32767) );
    type domain_clause_nt is table of domain_clause_t;
    
    type domain_policy_t is  record ( rn int, domain_priv varchar2(50),stat_dyn varchar2(50)
                                     , domain_clause varchar2(32767), column_list varchar2(32767)
                                     ,privilage_name varchar2( 256 byte) );
    type domain_policy_nt is table of domain_policy_t;
    
    function parse_head( txt clob ) return policy_meta;
    function parse_domains( txt in clob) return domain_clause_nt;
    function full_parse( domain_clause in domain_clause_nt ) return domain_policy_nt;
    
    function generate_code( pol_meta in policy_meta, domains in domain_policy_nt )  return clob;

end;
/

create or replace
package body app_policy_proceesssor
as

    function parse_head( txt clob ) return policy_meta
    as
        ret_val policy_meta;
    begin

with parseme as (
select x.*
from xmltable ( '/cmd/token'
  passing ddl_parser.convert2tree(ddl_parser.normalize_code(txt)) 
  columns
    rn for ORDINALITY,
    token varchar2(50) path '/token'
) x
)
select *
   into ret_val
from parseme
MATCH_RECOGNIZE (
    order by rn
    measures
        first( obj_name.token ) as policy_name,
        bypass.token          as bypass_clause
    pattern ( w1 w2 w3 obj_name w4 list_start obj_name+ list_end bypass*)
    define
        w1  as token = 'create',
        w2  as token = 'application',
        w3  as token = 'policy',
        w4  as token = 'for',
        list_start as token = '(',
        list_end   as token = ')',
        bypass     as token in ( 'owner_bypass', 'no_owner_bypass' ),
        obj_name as 1=1
);
        return ret_val;
    end;
    
    function  parse_domains( txt in clob) return domain_clause_nt
    as
        ret_val domain_clause_nt;
    begin

----------------------------------
        with parseme as (
        select x.*
        from xmltable ( '/cmd/token'
          passing ddl_parser.convert2tree(ddl_parser.normalize_code(txt)) 
          columns
            rn for ORDINALITY,
            token varchar2(50) path '/token'
        ) x
        )
        select mn,  max(  domain_priv  )  domain_priv,  max( stat_dyn  ) as stat_dyn
           ,listagg( token, '  ' )  within group  ( order by rn )  code_txt
           bulk collect into ret_val
        from parseme
        MATCH_RECOGNIZE (
            order by rn
            measures
                coalesce( w_priv.token, first(ref_cd.token), domain.token) as domain_priv,
                stat_dyn.token as  stat_dyn,
                MATCH_NUMBER()      as mn
            ALL ROWS PER MATCH
            ---domain list_start obj_name+? list_end acls list_start obj_name (comma_cd  obj_name)* list_end stat_dyn* comma_cd*
            --- domain (list_start obj_name+ list_end)* ref_cd obj_name list_start obj_name (comma_cd  obj_name)* list_end comma_cd*
            --- w_priv  obj_name w_prot w_cols list_start obj_name (comma_cd  obj_name)* list_end comma_cd*
            pattern ( (domain list_start obj_name+ list_end acls list_start obj_name (comma_cd  obj_name)* list_end stat_dyn* comma_cd*) |
                      (domain (list_start obj_name+ list_end)* ref_cd obj_name list_start obj_name (comma_cd  obj_name)* list_end comma_cd*) |
                      (w_priv  obj_name w_prot w_cols list_start obj_name (comma_cd  obj_name)* list_end comma_cd*)
                    )
            define
                w_priv       as token = 'privilege',
                w_prot       as token = 'protects',
                w_cols       as token = 'columns',
                domain     as token = 'domain',
                acls       as token = 'acls',
                comma_cd   as token = ',',
                ref_cd     as token =  'references',
                list_start as token = '(',
                list_end   as token = ')',
                stat_dyn   as token in ('static','dynamic'),
                obj_name   as  not next(obj_name.token) = 'acls' --token != ')' --- and next( obj_name.token) = 'acls' 
        )
        group by  mn
        order by domain_priv;

        return ret_val;
    end;
    function full_parse( domain_clause in domain_clause_nt ) return domain_policy_nt
    as
        ret_val domain_policy_nt;
    begin
        with inputdata( mn, domain_priv, stat_dyn, code ) as (
            select *
            from table( domain_clause )
        ), domain_data as  (
            select *
            from  inputdata
            where domain_priv  = 'domain'
        ), privilege_data as  (
            select *
            from  inputdata
            where domain_priv  = 'privilege'
        ), references_data as  (
            select *
            from  inputdata
            where domain_priv  = 'references'
        ), acl_list_tab as (
            select mn rn, domain_priv, nvl(  stat_dyn, 'dynamic' ) stat_dyn
            ,trim(substr( code, fp, sp -  fp )) acl_list
            from (
            select instr( code, 'acls  (') + length( 'acls  (') fp
                ,instr( code, ')', instr( code, 'acls  (') + length( 'acls  (')) sp
            ,substr( code, instr( code, 'acls  (') + length( 'acls  (')
                , instr( code, ')', instr( code, 'acls  (') + length( 'acls  (')) - instr( code, 'acls  (') + length( 'acls  (')) asd
                
            , domain_priv, stat_dyn, code, mn
            from domain_data
            )
        ), domains as (
            select mn rn, substr( code, length( 'domain  (  ' ), instr(code, ')  acls' ) - length( 'domain  (  ' )) domain_clause
            from domain_data
        ), final_domain as (
            select rn, domain_priv, stat_dyn, domain_clause, acl_list
            from domains d
                join acl_list_tab a using (rn)
        ), final_privileges as (
            select mn rn,  domain_priv, stat_dyn,
            trim( substr( code, length( 'privileege  '), instr( code, ' protects') - length( 'privileege  '))) privilege_name
            ,substr( code
                    ,instr( code, 'protects  columns  (  ') + length( 'protects  columns  (  ') 
                    ,instr( code, ')', instr( code, 'protects  columns  (  ') + length( 'protects  columns  (  ')) 
                      - (instr( code, 'protects  columns  (  ') + length( 'protects  columns  (  ') ) 
            )  column_list
            from privilege_data
        ), final_reeferences as (
        select mn rn, domain_priv, stat_dyn
        ,trim(substr( code, length('domain  ( ' ), instr(  code, ' )  references') - length('domain  ( ') ) )  domain_clause
        ,trim( substr(  code  ,instr( code, 'references' ) + length( 'references' ),
        instr( code, '(', instr( code, 'references' ) ) - ( instr( code, 'references' ) + length( 'references' ) ) ) ) TARGET_schema_TABLE
        ,trim(substr( code, instr(  code, '(', instr( code, 'references' ) ) +  2
         ,instr(  code, ')', instr( code, 'references' ) ) - ( instr(  code, '(', instr( code, 'references' ) ) +  2 )
         )) target_keys
        from  references_data
        )
        select *
            bulk collect into  ret_val
        from (
            select  rn, domain_priv, stat_dyn, domain_clause, acl_list  as column_list,  NULL privilege_name
            from final_domain
            union all
            select rn, domain_priv, stat_dyn, null domain_clause,column_list, privilege_name
            from  final_privileges
            union  all
            select rn, domain_priv, stat_dyn, domain_clause, target_keys as column_list,  TARGET_schema_TABLE as  privilege_name
            from final_reeferences
        )order by rn
        ;
    
    
        return ret_val;
    end;
    
    function generate_code( pol_meta in policy_meta, domains in domain_policy_nt )  return clob
    as
    begin
        return null;
    end;
    
$if false $then
with data(txt) as (
select q'[
create application policy hr_policy for (
  domain ( 1 = 1 ) acls  ( hr_represnitivee  ),
  domain ( department_id=60) acls ( it_department ) static,
  domain ( email =  xs_sys_context( 'xs$session', 'username' ) ) acls ( employee ),
  privilege view_salary protects columns ( salary ),
  domain references hr.employees(employee_id),
  domain ( private = 0 ) references hr.employees( department_id )
) no_owner_bypass
]' from dual
)
select *  from data
$end

end;
/
