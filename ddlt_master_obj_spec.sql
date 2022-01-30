create or  replace
type ddlt_master_obj is object (
    command_txt    varchar2(50), -- create,alter,drop
    object_type    varchar2(50), -- security class, acl, policy
    original_text  clob,
    tokens         tokens_nt,
    parsed_code    clob, -- json
    constructor function ddlt_master_obj( txt in clob ) RETURN self as result,
    member procedure init( txt in clob ),
    member procedure parse_and_store_tokens,
    member procedure parse_command_and_object,
    member procedure generate_json, -- public
    member function  generate_code(self in out ddlt_master_obj) return  clob, --public
    
    not final member procedure parse_create_command,
    not final member procedure parse_alter_command,
    not final member procedure parse_drop_command,

    not final member function generate_create_code return clob,
    not final member function generate_alter_code return clob,
    not final member function generate_drop_code return clob
) not final;
/
