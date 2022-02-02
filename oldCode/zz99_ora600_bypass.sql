create global temporary table temp_tokens of tokens_t;
create global temporary table temp_prince_priv (
    principal_name varchar2(50),
    privilege_name varchar2(50)
);


with  data(txt) as ( select q'[
    create application acl hr_acl for security class hrpriv aces (
        hr_representive => ( insert,update,select,delete,view_salary ),
        auditor => ( select, view_salary )
    )]'
    
    from dual
), token_table as (
select  x.*
from data d,  table(  ddl_parser_util.convert2token( d.txt ) ) x
),aces_list as (
                select  json_object( 'principal' value principal_name
                    ,'privilege' value json_arrayagg( privilege_name ) )ace
                from (
                    select distinct principal_name principal_name
                        ,privilege_name   privilege_name
                    from token_table                    
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
            
                            o_principal_name as 1=ddl_parser_util.always_true(3),
                            l_privilege      as 1=ddl_parser_util.always_true(3)
                    )
                )
--                where privilege_name is not null
                group by principal_name
        )
        select json_serialize( json_object( 'acl_name' value 'ACL NAME'
                          , 'security_class_name' value 'SECCLASS  NAME'
                          , 'aces' value json_arrayagg( aces_list.ace) 
                          )  pretty  ) json
        from aces_list;



"{
  "acl_name" : "ACL NAME",
  "security_class_name" : "SECCLASS  NAME",
  "aces" :
  [
    {
      "principal" : "auditor",
      "privilege" :
      [
        "view_salary",
        "select"
      ]
    },
    {
      "principal" : "hr_representive",
      "privilege" :
      [
        "view_salary",
        "delete",
        "select",
        "update",
        "insert"
      ]
    }
  ]
}"