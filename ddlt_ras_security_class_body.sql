create or replace
type body ddlt_ras_security_class
as
    constructor function ddlt_ras_security_class( txt clob ) return self as result
    as
    begin
        (self as ddlt_master_obj).init(txt);
        return;
    end;
    
    OVERRIDING member procedure parse_create_command
    as
    begin
        null;
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
        return 'create securiity class';
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_alter_code return clob
    as
    begin
        return 'alter securiity class';
    end;
    
/******************************************************************************/

    OVERRIDING member function generate_drop_code return clob
    as
    begin
        return 'drop securiity class';
    end;
    
/******************************************************************************/
end;
/
