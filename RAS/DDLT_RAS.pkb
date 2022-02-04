create or replace
package body ddlt_ras
as
    function get_pattern( obj_type in ddlt_util.ras_obj_name_t ) return clob
    as
    begin
        if patterns.exists(obj_type)
        then
            return patterns(obj_type);
        else
            raise ddlt_util.general_error;
        end if;
    end;

    /* Fetches the appropriate MATCH_RECOGNIZE PATTERN
    * 
    * @param obj_typ type of RAS object who's PATTERN you desire
    * @return appropriate MATCH_RECOGNIZE PATTERN
    * @throws general_error thrown when requested obj_type not found
    */
    function get_define( obj_type in ddlt_util.ras_obj_name_t ) return  ddlt_util.mr_define_exp_hash
    as
    begin
         if defines.exists(obj_type)
        then
            return defines(obj_type);
        else
            raise ddlt_util.general_error;
        end if;
    end;
    
    function generate_json( obj_type in ddlt_util.ras_obj_name_t ) return clob
    as
        ret_val clob;
    begin
        return ret_val;
    end;
    
    function generate_code_from_json( json_txt in ddlt_util.ras_obj_name_t ) return clob
    as
        ret_val clob;
    begin
        return ret_val;
    end;
    
    function generate_code( obj_type in ddlt_util.ras_obj_name_t ) return clob
    as
        ret_val clob;
        json_txt clob;
    begin
        json_txt := generate_json( obj_type );
        ret_val  := generate_code_from_json( json_txt );
        
        return ret_val;
    end;
    
    
end;
/