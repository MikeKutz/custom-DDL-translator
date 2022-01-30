create or replace package body ddlt_util
as
    function  normalize_code( txt in clob ) return clob
    as
        ret_value clob := txt;
    begin
        --   remove comments
        ret_value := regexp_replace(  txt , '--.*$', ' ', 1,  0, 'm' );
        
        --  make 1 line
        ret_value  := regexp_replace(  ret_value, chr(10), ' ' );
        
        
        ret_value  := regexp_replace(  ret_value, '([\(\),]|=>)', ' \1  ' );
        
        -- sinle spaces
        while (regexp_like( ret_value, '  ' )  )
        loop
          ret_value  := regexp_replace(  ret_value, '  ', ' ' );
        end loop;
        
        return trim(ret_value);
    end  normalize_code;
    
/******************************************************************************/

    function convert2tree( txt in clob ) return xmltype
    as
        tmp_clob clob := txt;
        ret_value xmltype;
    begin
        tmp_clob := regexp_replace( txt, ' ', '</token><token>' );
        tmp_clob := to_clob( '<cmd><token>' ) || tmp_clob ||  to_clob( '</token></cmd>');
        
        return xmltype( tmp_clob );
    end convert2tree;
    
/******************************************************************************/

    function always_true( n in int ) return int DETERMINISTIC
    AS
    begin
        return 1;
    end always_true;


end;