create or replace
type ddlt_ras_security_class under ddlt_master_obj (
    constructor function ddlt_ras_security_class( txt clob ) return self as result,
    OVERRIDING member procedure parse_create_command,
    OVERRIDING member procedure parse_alter_command,
    OVERRIDING member procedure parse_drop_command,

    OVERRIDING member function generate_create_code return clob,
    OVERRIDING member function generate_alter_code return clob,
    OVERRIDING member function generate_drop_code return clob
)