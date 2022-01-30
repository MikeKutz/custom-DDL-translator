create or replace
package ddlt_ras_const
as

    type security_class_info_t is record 
                              ( security_class_name ddlt_util.ras_obj_name_t );
    type policy_info_t is record ( policy_name      ddlt_util.ras_obj_name_t );
    
    -- acl types
    type acl_info_t is record ( acl_name            ddlt_util.ras_obj_name_t
                               ,security_class_name ddlt_util.ras_obj_name_t );
    type ace_t       is record ( principal_name     ddlt_util.ras_obj_name_t
                                ,privilege_name     ddlt_util.ras_obj_name_t );
    type ace_nt is table of ace_t;
    

end;
/
