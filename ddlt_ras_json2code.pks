create or replace
package ddlt_ras_json2code
as
    /* Convert JSON to code for RAS objects
    *  - security class
    *  - acl
    *  - policy
    *
    * this uses tePLSQL to generate code
    * templates are in the body of this package
    *
    * @headcom
    */
    cursor parse_security_class_info( json_txt clob ) return ddlt_ras_const.security_class_info_t is
                    select z.security_class_name
                    from json_table( json_txt, '$'
                    columns
                        security_class_name
                    ) z;
            
    cursor parse_acl_info( json_txt clob ) return ddlt_ras_const.acl_info_t is
                    select z.acl_name, z.security_class_name
                    from json_table( json_txt, '$'
                    columns
                        acl_name,
                        security_class_name
                    ) z;
                    
    cursor parse_acl_entries( json_txt clob ) is
                    select z.principal, z.priv
                        ,row_number() over (order by principal, priv) is_first
                        ,row_number() over (order by principal desc, priv desc) is_last
                    from json_table( json_txt, '$.aces[*]'
                    columns
                        principal,
                    nested privileges[*] columns (
                       priv varchar2(50) path '$' )) z
                    order by principal, priv;
            
    cursor parse_policy_info( json_txt clob ) return ddlt_ras_const.policy_info_t is
            select null from dual;
    cursor parse_policy_domain( json_txt clob ) is
            select null from dual;
    cursor parse_policy_privileges( json_txt clob ) is
            select null from dual;
    cursor parse_policy_FKs( json_txt clob ) is
            select null from dual;
    /* main code generator call
    *
    */
    function generate_code( json_txt clob, cmd varchar2, obj varchar2 )
        return clob;
        
    function generate_security_class_create( txt clob ) return clob;
    function generate_acl_create( txt clob ) return clob;
    function generate_policy_create( txt clob ) return clob;
end;
/
