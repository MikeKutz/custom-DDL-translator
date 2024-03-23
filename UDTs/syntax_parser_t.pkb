create or replace
type body syntax_parser_t
as
  constructor function syntax_parser_t( self in out nocopy syntax_parser_t, act in varchar2, grp varchar2, obj varchar2) return self as result
  as
  begin
    self.init( act, grp, obj);
    self.assert_name();
    
    return;
  exception
    when no_data_found then
      raise_application_error( -20001, 'Invalid syntax object "' || act || '","' || grp || '"' || obj || '"' );
  end syntax_parser_t;
  
  member procedure init( self in out nocopy syntax_parser_t, act in varchar2, grp in varchar2, obj in varchar2)
  as
  begin
      select value(a) into self
      from syntax_lists a
      where a.syntax_action = act
        and a.syntax_group  = grp
        and a.syntax_subtype = obj;

      self.is_saved := true;
  exception
    when no_data_found then
      self.syntax_action := act;
      self.syntax_group  := grp;
      self.syntax_subtype := obj;
  end init;

  member procedure reset_syntax( self in out nocopy syntax_parser_t, act in varchar2, grp in varchar2, obj in varchar2)
  as
  begin
      self.update_match_string();
      
      self.matchrecognize_pattern := 'start';
      self.matchrecognize_define  := new MKLibrary.Hash_t();
      
      self.code_template          := new teJSON.Blueprint();
      
      self.is_saved := false;
  end;


  member procedure assert_name(self in out nocopy syntax_parser_t )
  as
    dummy dual.dummy%type;
  begin
    select a.dummy into dummy
    from dual a
    where domain_check( MKLibrary.object_name_d, self.syntax_action ) is true
      and domain_check( MKLibrary.object_name_d, self.syntax_group ) is true
      and domain_check( MKLibrary.object_name_d, self.syntax_subtype ) is true;
  exception
    when no_data_found then
      raise_application_error( -20001, 'Invalid syntax assignment set "' || self.syntax_action || '","' || self.syntax_group || '","' || self.syntax_subtype || '"' );
  end;
  
  member procedure assert_matchrecognize(self in out nocopy syntax_parser_t )
  as
    no_syntax_defined       exception;
    not_a_pattern           exception;
    not_a_blueprint         exception;
    missing_define_elements exception;
  begin
    -- CLOB not null (pattern)
    if self.matchrecognize_pattern is null
    then
      raise no_syntax_defined;
    end if;

    if false
    then
      raise not_a_pattern;
    end if;
    
    -- Blueprint CLOB is JSON of Schema xxx
    if false
    then
      raise not_a_blueprint;
    end if;
    
    -- all elements of `pattern` are defined in `template`
    if false
    then
      raise missing_define_elements;
    end if;
  exception
    when no_syntax_defined then raise_application_error( -20002, 'No `pattern` defined');
    when not_a_pattern then raise_application_error( -20003, '`pattern` not valid');
    when not_a_blueprint then raise_application_error( -20004, 'Blueprint not valid');
    when missing_define_elements then raise_application_error( -20005, 'Missing element in `define`');
  end;

  member procedure assert_template(self in out nocopy syntax_parser_t )
  as
  begin
    null;
  end;

  member procedure assert_match_string(self in out nocopy syntax_parser_t )
  as
  begin
    null;
  end;
  
  member procedure assert(self in out nocopy syntax_parser_t )
  as
  begin
    self.assert_name();
    self.assert_matchrecognize();
    self.assert_template();
    self.assert_match_string();
  end;
  
  member procedure assert_parsed( self in out nocopy syntax_parser_t, parsed JSON)
  AS
    is_valid  number(1);
    j         json;
  begin 
    -- TODO - not final
    -- overloaded version checks
    --   [not] exists of DB objects
    --   required keywords
    --   other "completeness"
    
    if self.parsed_sql_schema is NULL
    then
      return;
    end if;
      j := JSON( self.parsed_sql_schema );
      is_valid := dbms_json_schema.is_valid( parsed, j, dbms_json_schema.raise_none );
    if is_valid = 1
    THEN 
      return;
    end if;

    RAISE_APPLICATION_ERROR(-20710, 'Invalid SQL' );
  end assert_parsed;
  
  member procedure add_group(self in out nocopy syntax_parser_t )
  as
  begin
    self.assert_name();
    
    insert into syntax_groups (group_name) values (self.syntax_group);
  exception
    when dup_val_on_index then
      raise_application_error(-20002,'Group "' || self.syntax_group || '" already exists.');
    null;
  end;
  
  member procedure drop_group(self in out nocopy syntax_parser_t )
  as
  begin
    delete from syntax_groups where group_name = self.syntax_group;
  end;
  
  member procedure upsert_group(self in out nocopy syntax_parser_t, syntax_desc in varchar2  )
  as
  begin
    merge into cSQL.syntax_groups a
    using (values (self.syntax_group
                  ,upsert_group.syntax_desc) ) b(group_name, group_desc)
    on (a.group_name=b.group_name)
    when matched then update set a.group_desc=b.group_desc
    when not matched then insert (group_name,group_desc) values (b.group_name, b.group_desc);
  end;
  
  member procedure upsert_syntax(self in out nocopy syntax_parser_t )
  as
  begin
    self.update_match_string();
    self.assert();
    
    self.is_saved := true;
    
    merge into cSQL.syntax_lists a
    using (values (self)) b(obj)
    on (a.syntax_action = b.obj.syntax_action
      and a.syntax_group = b.obj.syntax_group
      and a.syntax_subtype = b.obj.syntax_subtype)
    when not matched then insert values (b.obj)
    when matched then update
          set a.matchrecognize_pattern = b.obj.matchrecognize_pattern
          ,a.matchrecognize_define = b.obj.matchrecognize_define
          ,a.code_template = b.obj.code_template
          ,a.is_saved = b.obj.is_saved
          ,a.match_string = b.obj.match_string;
          ---
  end;
  
  member procedure delete_syntax(self in out nocopy syntax_parser_t )
  as
  begin
    self.is_saved := false;

    delete from syntax_lists a
    where a.syntax_action = self.syntax_action
      and a.syntax_group  = self.syntax_group
      and a.syntax_subtype = self.syntax_subtype;
  end;
  
  member procedure update_match_string(self in out nocopy syntax_parser_t )
  as
  begin
    self.match_string := self.syntax_action || ' ' || self.syntax_group || ' ' || self.syntax_subtype || ' %';
  end;
  
  member function get_pattern(self in out nocopy syntax_parser_t ) return clob
  as
  begin
    return self.matchrecognize_pattern;
  end;
  
  member function get_define(self in out nocopy syntax_parser_t )  return clob
  as
    temp     cSQL.parser_util.matchrecognize_define_expression_hash;
    ret_val  clob;
  begin
    temp    := cSQL.parser_util.hash2aa( self.matchrecognize_define);
    ret_val := cSQL.parser_util.define_hash_to_clause( temp );

    return ret_val;
  end;
  
  member function get_matchrecognize(self in out nocopy syntax_parser_t ) return clob
  as
    ret_value clob;
  begin
    -- returns full match_recognize clause
    raise_application_error( -20000, 'Code not Implemented');

    return null;
  end;
  
  member procedure assert_syntax( self in out nocopy syntax_parser_t, code clob)
  as
  begin
    -- TODO - not final
    -- assert it matches self.match_string
    -- assert counts of `(` and `)` match
    -- overload adds individual cheks
    null;
  end;
  
  member function transpile( self in out nocopy syntax_parser_t, code clob ) return JSON
  as
    parsed_tokens  cSQL.tokens_nt;
    debug_sql_txt  clob;

    code_json      JSON;
  begin
    self.assert();
    self.assert_syntax( code );
    
    parsed_tokens :=  cSQL.parser_util.pattern_parser(   statement_txt  => code
                                                        ,pattern_txt    => self.matchrecognize_pattern
                                                        ,custom_dev     => cSQL.parser_util.hash2aa( self.matchrecognize_define)
                                                        ,sql_txt        => debug_sql_txt
                                                        ,run_sql        => true);

    code_json := cSQL.parser_util.parsed_tokens_to_json( parsed_tokens );
    
    return code_json;
  end;

member function build_code( self in out nocopy syntax_parser_t, parsed_sql   JSON) return clob
as
  ret_value  clob;
  e          teJSON.Engine_t;
begin
  <<assert_input>> -- turn to RAISE <exception>
  begin
    if parsed_sql is NULL then goto EOF; end if;
    if self.code_template is NULL then goto EOF; end if;
    if self.execution_snippet is NULL then goto EOF; end if;

    -- assert.parsed_sql( parsed_sql )

  end;

  -- initialize Engine_t
  e := new teJSON.Engine_t( self.code_template );

  -- set Engine_t.params (turn off errors TODO)
  null;

  -- set Engine_t.vars
  e.vars.json_clob := json_serialize(parsed_sql);

  -- actually generate code
  ret_value := e.render_snippet( self.execution_snippet );

  <<EOF>>
  return ret_value;
end;

end;
/

  
  