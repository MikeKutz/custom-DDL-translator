create or replace package ddlt_util
as
    /*
    * utility packagee for  preparing  and  parsing commands
    *
    *  TODO   append/prepend  'util' to name
    *
    * @headcom
    */
    subtype ras_obj_name_t is varchar2(50);

    type ddl_info_t is record (  command_text   ras_obj_name_t
                                ,command_group  ras_obj_name_t
                                ,object_type    ras_obj_name_t );
    
    general_error exception;
    
    PRAGMA EXCEPTION_INIT (general_error, -20700);
    
    /*
    * function removes comments  and double-spaces and chr(10)
    * it WILL interfere with quotes
    *
    * @param txt unclean command  line
    * @return cleeaneed command  line
    */
    function  normalize_code( txt in clob ) return clob;
    
    /*
    *  converts  a  CLEAN command line  into tokens to be proceessed
    *
    * XMLPath  = /cmd/token
    * 
    * @param txt CLEAN  command line
    * @return   parsed XML  tree of  tokens
    */
    function convert2tree( txt in clob ) return xmltype;
    
    /*
    * overload for '1=1' pattern definition of MATCH_RECGONIZE
    */
    function always_true( n in int ) return int DETERMINISTIC;
end;
/
