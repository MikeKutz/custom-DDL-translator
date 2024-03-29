create or replace
type body db_object_triplet
as
  constructor function db_object_triplet return self as result
  as
  begin
    parts := 0;

    return;
  end db_object_triplet;

  constructor function db_object_triplet( self in out nocopy db_object_triplet, txt in varchar2 ) return self as result
  as
  begin
    self.init(txt);
    return;
  end db_object_triplet;

  member procedure init(self in out nocopy db_object_triplet, txt in varchar2 )
  as
  subtype regexp_text is varchar2(400);

  sql_name            constant regexp_text := '("[^"]+?"|[[:alpha:]][[:alnum:]_\$]+)';
  sql_just_name       constant regexp_text := '^' || sql_name || '$';
  sql_name_name       constant regexp_text := '^' || sql_name || '\.' || sql_name || '$';
  sql_name_name_name  constant regexp_text := '^' || sql_name || '\.' || sql_name || '\.' || sql_name || '$';
  begin
    case
      when regexp_like( txt, sql_name_name_name ) then
        self.parts := 3;

        self.last_name   := ( regexp_replace( txt, sql_name_name_name, '\1') );
        self.middle_name := ( regexp_replace( txt, sql_name_name_name, '\2') );
        self.first_name  := ( regexp_replace( txt, sql_name_name_name, '\3') );
      when regexp_like( txt, sql_name_name ) then
        self.parts := 2;

        self.last_name   := ( regexp_replace( txt, sql_name_name, '\1') );
        self.middle_name := null;
        self.first_name  := ( regexp_replace( txt, sql_name_name, '\2') );
      when regexp_like( txt, sql_just_name ) then
        self.parts := 1;

        self.first_name  := ( txt );
      else
        self.parts := 0;

        self.first_name := 'no body home';
    end case;

    return;
  end init;
end;
/
