create or replace
type body ddlt_ras_acl
as
    constructor function ddlt_ras_acl( txt in clob ) return self as result
    as
    begin
        (self as ddlt_master_obj).init(txt);
        
        return;
    end;
    
    OVERRIDING member procedure parse_create_command
    as
        head_info    ddlt_ras_const.acl_info_t;
        prince_priv  ddlt_ras_const.ace_nt;
    begin
        /* Algorithm
           1) extract head
           2) extract acees
           3) build JSON
           
           note: ORA600 when MATCH_RECGONIZE uses Nested Tables or is in CTE
        */
        
        -- extract head
        select acl_name, sec_name
            into head_info
        from table( self.tokens )
        MATCH_RECOGNIZE (
           order  by rn
            MEASURES
                o_acl_name.token  as acl_name,
                o_sc_name.token   as sec_name
            pattern ( w_create w_application  w_acl o_acl_name w_for w_security w_class o_sc_name  w_aces  c_start_list
                         o_principal_name c_hash_code c_start_list l_privilege (c_comma l_privilege)* c_end_list
                         (c_comma  o_principal_name c_hash_code c_start_list l_privilege (c_comma l_privilege)* c_end_list)*
                      c_end_list )
            DEFINE
                w_create        as token = 'create',
                w_application   as token = 'application',
                w_acl           as token = 'acl',
                w_for           as token = 'for',
                w_security      as token = 'security',
                w_class         as token = 'class',
                w_aces          as token  = 'aces',

                c_start_list  as token = '(',
                c_end_list    as token = ')',
                c_hash_code   as token = '=>',
                c_comma       as token = ',',

                o_acl_name       as 1=ddlt_util.always_true(1),
                o_sc_name        as 1=ddlt_util.always_true(2),
                o_principal_name as 1=ddlt_util.always_true(3),
                l_privilege      as 1=ddlt_util.always_true(3)
        );
        
        -- extract ACES
        <<ora600workaround>>
        begin
            savepoint workaround_sp;
            
            delete from ddlt_tokens_temp;
            delete from ddlt_matched_tokens_temp;
            
            insert into ddlt_tokens_temp
            select * from table( self.tokens );
                
            insert into ddlt_matched_tokens_temp ( match_class, token  )
            select zztop.principal_name principal_name
                ,zztop.privilege_name   privilege_name
            from ddlt_tokens_temp 
            MATCH_RECOGNIZE (
               order  by rn
                MEASURES
                    o_principal_name.token  as principal_name,
                    l_privilege.token       as privilege_name,
                   MATCH_NUMBER() AS mno,
                   CLASSIFIER() AS cls
                ALL ROWS PER MATCH -- cause ORA-600
                pattern (  o_principal_name c_hash_code c_start_list l_privilege (c_comma l_privilege)* c_end_list )
                DEFINE
    
                    c_start_list  as token = '(',
                    c_end_list    as token = ')',
                    c_hash_code   as token = '=>',
                    c_comma       as token = ',',
    
                    o_principal_name as 1=ddlt_util.always_true(3),
                    l_privilege      as 1=ddlt_util.always_true(3)
            ) zztop ;
    
            -- build JSON
            with aces_list as (
                select json_object( 'principal' value a.principal_name
                            ,'privileges' value json_arrayagg( a.privilege_name )
                        ) ace
                from (
                    select distinct b.match_class principal_name, b.token privilege_name
                    from ddlt_matched_tokens_temp b
                ) a
                group  by a.principal_name
            )
            select json_serialize( json_object( 'acl_name' value head_info.acl_name
                              , 'security_class_name' value head_info.security_class_name
                              , 'aces' value json_arrayagg( aces_list.ace) 
                              )
                        pretty )
                into self.parsed_code                        
            from aces_list;
    
            rollback to workaround_sp;
        end;
        
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
        ret_val clob;
        current_principal varchar2(50);
        
        procedure gen_head
        as
            n int;
        begin
            select  to_number(json_value(  self.parsed_code, '$.aces.count()' ))
                into n
            from dual;
            
            n := n + 1;
            
            ret_val := q'[
declare
    aces XS$ACE_LIST := new XS$ACE_LIST();
    priv XS$LIST;
    empty_priv XS$LIST := new XS$LIST();
begin
    --  ace count = ]' || nvl( to_char(n), 'n/a') || q'[
]';
        end;
        
        procedure gen_clean_priv_list
        as
        begin
            ret_val := ret_val || q'[
    priv := empty_priv;]';    
        end;
        
        procedure gen_priv_list( priv in varchar2  )
        as
        begin
        ret_val := ret_val || q'[
    priv_list.extend(1); priv( priv.last ) := ']' || priv || q'[';]';
        end;
        
        procedure gen_ace( principal in varchar2 )
        as
        begin
            ret_val := ret_val || q'[

    ace.extend(1);
    ace( ace.last ) :=  XS$ACE_TYPE( principal => ']' || principal || q'[',
                                     privilege => priv
               );
---------------------------------------------------------------
]';
        end;
        
        procedure gen_policy( acl_name in varchar2, sec_class in varchar2 )
        as
        begin
            ret_val := ret_val || q'[
    xs_acl.create_acl( aces => aces,
                acl_name => ']'  || acl_name || q'[',
                sec      =>  ']' || sec_class || q'['
            );
end;
/
]';
        end;
        
    begin
    
        gen_head;
        
        for rec in (
                    select z.*
                    from json_table( self.parsed_code, '$.aces[*]'
                    columns
                        principal,
                    nested privileges[*] columns (
                       priv varchar2(50) path '$' )) z
                    order by principal, priv)
        loop
            if nvl(current_principal,'----') != rec.principal then
                if current_principal is not null
                then
                    gen_ace( current_principal );
                end if;
                gen_clean_priv_list;
            end if;
            gen_priv_list( rec.priv );
            current_principal := rec.principal;
        end loop;
        gen_ace( current_principal );


        gen_policy( json_value( self.parsed_code, '$.acl_name' ), json_value( self.parsed_code, '$.security_class_name' ));
    
        return ret_val;
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_alter_code return clob
    as
    begin
        return 'alter acl';
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_drop_code return clob
    as
    begin
        return 'drop acl';
    end;
    
/******************************************************************************/
$if false $then
-- sample code
with data(txt) as ( select q'[
create application acl hr_acl for security class hrpriv aces (
    hr_representive => ( insert,update,select,delete,view_salary ),
    auditor => ( select, view_salary )
)]' from dual
)
select * from data
$end

$if false $then
<% property( generate_acl ) %>
<%!
   acl_name  varchar(50);
   sec_class varchar(50);
   ace_json   clob;
   n          int;
%>
<% n := 20; %>
-- code generator "create applicationn acl"
declare
    aces xs$ace_typee;
begin
    aces.extend(<%= n  %>);
    
    <% for i in 1 .. n loop %>
    aces(<%= i %>) := XS$ACE_TYPE( principal => '<%= lkjljlj $>',
            privilege => XS$LIST( ... )
            );
    
    <% end loop; %>
    
    xs_acl.create_acl(  acl_name        =>  '<%= acl_name %>',
                        security_class  => '<%= sec_class %',
                        aces            =>
                    );
end;
<%= '/' %>
$end

end;
/
