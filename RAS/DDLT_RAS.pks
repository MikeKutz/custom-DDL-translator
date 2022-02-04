create or replace
package ddlt_ras
as
    /* generates code for RAS objects
    *
    *
    * SECURITY CLASS JSON FORMAT (planned)
    * { OBJECT_TYPE:security_class OBJECT_NAME:hr_priv under:[ sys.dml, sys.ns ] privileges:[view_salary,ppi] }
    *
    * ACL JSON FORMAT
    * { OBJECT_TYPE:acl, OBJECT_NAME:hr_acl, SECURITY_CLASS:hr_sc aces:[
    *                   {principal:hr_rep  aces:[insert,select,update,delete,view_salaary]},
    *                   {principal:auditor aces:[select,view_salary]]
    *               ]
    * }
    *
    * POLICY JSON FORMAT (planned)
    * { OBJECT_TYPE:policy OBJECT_NAME:hr_priv protects:[
    *      -- RLS
    *      { TYPE:rls realm:"1=1" acls:[ hr_acl ] },
    *      -- FK
    *      { TYPE:foreign keys:[employee_id, department_id] TARGET_TABLE:hr.empployees columns:[ emp_no, dept_no] where:" is_private = 1" },
    *      { TYPE:column privilege:view_salary columns:[ salary ] }
    * }
    *
    *
    * @headcom
    */

    /* constants for type of RAS object */
    security_class constant ddlt_util.ras_obj_name_t := 'security_class';
    acls           constant ddlt_util.ras_obj_name_t := 'acl';
    policys        constant ddlt_util.ras_obj_name_t := 'policy';
    
    /* holds Match Recognize PATTERNs for RAS objects */
    patterns ddlt_util.mr_pattern_hash := ddlt_util.mr_pattern_hash(
        security_class => 'w_create w_application x_object_type x_object_name
                            n_under c_start_list l_item (c_comma l_item)* c_end_list
                            w_define n_privileges c_start_list l_item (c_comma l_item)* c_end_list',
                            
        acls => 'w_create w_application x_object_type x_object_name
        w_for w_security w_class x_security_class
        n_ace c_start_obj_array
            (n_principal o_principal_name n_privileges c_start_list l_priv (c_comma l_priv)*  c_end_list
        (c_obj_comma|c_end_obj_array))+',
        policys => 'w_create w_application x_object_type x_object_name n_for c_start_obj_array
        (
           (x_type n_domain c_start_exp e_item+? c_end_exp n_acls c_start_list l_item (c_comma l_item)* c_end_list (c_obj_comma | c_end_obj_array) )
         | ( x_type x_privilege_name w_protects n_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list (c_obj_comma | c_end_obj_array ) )
         | ( x_type n_source_columns c_start_list l_priv (c_comma l_priv)*  c_end_list
            w_references n_table o_table n_target_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list
            (n_where c_start_exp e_tok+ c_end_exp)?
        (c_obj_comma | c_end_obj_array) )
       )+',
/**************** debug/development patterns ***********/        
        'p_full' => 'w_create w_application x_object_type x_object_name n_for c_start_obj_array (
            ( x_type x_privilege_name w_protects n_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list ) |
            ( x_type n_domain c_start_exp e_item+? c_end_exp n_acls c_start_list l_item (c_comma l_item)* c_end_list )|
            ( x_type n_source_columns c_start_list l_priv (c_comma l_priv)*  c_end_list
                w_references n_table o_table n_target_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list
                (n_where c_start_exp e_tok+ c_end_exp)? 
            )
        (c_obj_comma | c_end_obj_array))+',

        'p_priv_only' => 'w_create w_application x_object_type x_object_name n_for c_start_obj_array
        (x_type x_privilege_name w_protects n_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list
        (c_obj_comma | c_end_obj_array))+',
        
        'p_fk_only' => 'w_create w_application x_object_type x_object_name n_for c_start_obj_array
            (x_type n_source_columns c_start_list l_priv (c_comma l_priv)*  c_end_list
            w_references n_table o_table n_target_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list
            (n_where c_start_exp e_tok+ c_end_exp)?
        (c_obj_comma | c_end_obj_array)
       )+',
       
        'p_domain_only' => 'w_create w_application x_object_type x_object_name n_for c_start_obj_array
            (x_type n_domain c_start_exp e_item+? c_end_exp n_acls c_start_list l_item (c_comma l_item)* c_end_list
       (c_obj_comma | c_end_obj_array))+'
    );

    /* holds custom Match Recognize DEFINE expressions for RAS objects */
    defines ddlt_util.mr_define_hash_hash := ddlt_util.mr_define_hash_hash(
        security_class => ddlt_util.mr_define_exp_hash(
            'w_create'      => q'[token = 'create']', -- create
            'w_application' => q'[token = 'application']', -- application
            'x_object_type' => q'[token = 'security_class']', -- security_class
            'n_under'       => q'[token = 'under']',
            'w_define'      => q'[token = 'define']',
            'n_privileges'  => q'[token = 'privileges']'
        ),
        
        acls           => ddlt_util.mr_define_exp_hash(
            'w_create'      => q'[token = 'create']',
            'w_application' => q'[token = 'application']',
            'w_for' => q'[token = 'for']',
            'w_security' => q'[token = 'security']',
            'w_class' => q'[token = 'class']',
            'x_object_type' => q'[token = 'acl']',
            'n_aces'        => q'[token = 'aces']',
            'n_principal'   => q'[token = 'principal']',
            'n_privileges'  => q'[token = 'privileges']'
        ),

        policys        => ddlt_util.mr_define_exp_hash(
            'w_create'      => q'[token = 'create']',
            'w_application' => q'[token = 'application']',
            'x_object_type' => q'[token = 'policy']',
            'n_for'         => q'[token = 'for']',
            'x_type'         => q'[token in ( 'rls', 'foreign', 'privilege' )]',
            'n_domain'         => q'[token = 'domain']',
            'n_acls'         => q'[token = 'acls']',
            'n_source_columns'         => q'[token = 'source_columns']',
            'w_references'           => q'[token = 'references']',
            'n_table'               => q'[token = 'table']',
            'n_target_columns'         => q'[token = 'target_columns']',
            'n_where'               => q'[token = 'where']',
            'w_protects'           => q'[token = 'protects']',
            'n_columns'           => q'[token = 'columns']'

            )
    );
    
    /* Fetches the appropriate MATCH_RECOGNIZE PATTERN
    * 
    * @param obj_typ type of RAS object who's PATTERN you desire
    * @return appropriate MATCH_RECOGNIZE PATTERN
    * @throws general_error thrown when requested obj_type not found
    */
    function get_pattern( obj_type in ddlt_util.ras_obj_name_t ) return clob;

    /* Fetches the appropriate MATCH_RECOGNIZE PATTERN
    * 
    * @param obj_typ type of RAS object who's PATTERN you desire
    * @return appropriate MATCH_RECOGNIZE PATTERN
    * @throws general_error thrown when requested obj_type not found
    */
    function get_define( obj_type in ddlt_util.ras_obj_name_t ) return  ddlt_util.mr_define_exp_hash;

    function generate_json( obj_type in ddlt_util.ras_obj_name_t ) return clob;
    
end;
/