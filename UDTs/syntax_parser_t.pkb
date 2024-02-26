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
  
  member procedure upsert_syntax(self in out nocopy syntax_parser_t )
  as
  begin
    self.assert();
    
    self.is_saved := true;
    
    merge into syntax_lists a
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
  begin
    -- need to loop over all keys and generate DEFINE clause
    return null;
  end;
  
  member function get_matchrecognize(self in out nocopy syntax_parser_t ) return clob
  as
    ret_value clob;
  begin
    -- returns full match_recognize clause
    
    return null;
  end;
  
  member procedure assert_syntax( self in out nocopy syntax_parser_t, code clob)
  as
  begin
    -- applies syntax_regexp to code
    null;
  end;
  
  member function transpile( self in out nocopy syntax_parser_t, code clob ) return JSON
  as
    code_json JSON;
  begin
    self.assert();
    self.assert_syntax( code );

--    code_json := self.interprete( code );
    
    -- teJSON( ..., code_json );

    return null;
  end;
  
end;
/

  
  