create or replace
type body ddlt_master_obj
as
    constructor function ddlt_master_obj( txt in clob ) RETURN self as result
    as
    begin
        self.init( txt );
        
        return;
    end;
    
    member procedure generate_json
    as
    begin
        null;
    end;

    member procedure init( txt in clob )
    as
    begin
        self.original_text :=  txt;
        self.parse_and_store_tokens;
        self.parse_command_and_object;
        case self.command_txt
            when 'create' then
                self.parse_create_command;
            when 'create' then
                self.parse_alter_command;
            when 'create' then
                self.parse_drop_command;
            else
                raise  ddlt_util.general_error;  -- need better error
        end  case;
    
    end;


    member procedure parse_and_store_tokens
    as
    begin
        select tokens_t( null,null,x.rn, x. token  )
            bulk collect into self.tokens
        from xmltable ( '/cmd/token'
          passing ddlt_util.convert2tree(ddlt_util.normalize_code(self.original_text)) 
          columns
            rn for ORDINALITY,
            token varchar2(50) path '/token'
        ) x;

        null;
    end;
  
    member procedure parse_command_and_object
    as
    begin
        select command_txt, object_type -- missing ommand_group
            into self.command_txt, self.object_type
        from
        table(self.tokens)
        match_recognize (
            order by rn
            measures
                coalesce( o_create.token, o_alter.token, o_drop.token) as command_txt,
                coalesce( o_obj_policy.token, o_obj_acl.token, o_obj_sec.token || ' ' || o_obj_class.token )     as object_type
            pattern ( (o_create | o_alter | o_drop) w_application ( (o_obj_sec o_obj_class) | o_obj_acl | o_obj_policy ) )
            define
                -- command group
                w_application as token = 'application',
                
                -- command_txt
                o_create      as token = 'create',
                o_alter       as token = 'alter',
                o_drop        as token = 'drop',
                
                -- object_type
                o_obj_sec     as token = 'security',
                o_obj_class   as token = 'class',
                o_obj_acl     as token = 'acl',
                o_obj_policy  as token = 'policy'
        );
    end;

    member function generate_code(self in out ddlt_master_obj) return  clob
    as
        ret_val clob;
    begin
        case self.command_txt
            when 'create' then
                self.parse_create_command;
                ret_val := self.generate_create_code;
            when 'create' then
                self.parse_alter_command;
                ret_val := self.generate_alter_code;
            when 'create' then
                self.parse_drop_command;
                ret_val := self.generate_drop_code;
            else
                raise  ddlt_util.general_error;  -- need better error
        end  case;
        
        return ret_val;
    end;

    not final member procedure parse_create_command
    as
    begin
        return;
    end;

    not final member procedure parse_alter_command
    as
    begin
        return;
    end;

    not final member procedure parse_drop_command
    as
    begin
        return;
    end;

    not final member function generate_create_code return clob
    as
    begin
        return '-- code generator not implimented (' || self.command_txt || ','  || self.object_type || ')';
    end;

    not final member function generate_alter_code return clob
    as
    begin
        return '-- code generator not implimented (' || self.command_txt || ','  || self.object_type || ')';
    end;

    not final member function generate_drop_code return clob
    as
    begin
        return '-- code generator not implimented (' || self.command_txt || ','  || self.object_type || ')';
    end;

end;
/
