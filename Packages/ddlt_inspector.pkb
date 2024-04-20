create or replace
package body ddlt_inspector
as
  /* use by Developers of new Parser_t */
  procedure "_decode"( txt in  clob, act out varchar2, grp out varchar2, obj out varchar2 )
  as
    clean_txt clob;
    n         int;

    bad_ddl exception;
  begin
    clean_txt := txt;

    <<assert_txt>>
    begin
      n := length(clean_txt) - length( replace(clean_txt, ' ', null ) );
      if n < 2 then raise bad_ddl; end if;
    end;

    act := substr( clean_txt, 1, instr(clean_txt, ' ', 1, 1) - 1);
    grp := substr( clean_txt, instr(clean_txt, ' ', 1, 1) + 1, instr(clean_txt, ' ', 1, 2) - 1 - instr(clean_txt, ' ', 1, 1) ) ;
    obj := substr( clean_txt, instr(clean_txt, ' ', 1, 2) + 1, instr(clean_txt, ' ', 1, 3) - 1 - instr(clean_txt, ' ', 1, 2) );
  EXCEPTION
    when bad_ddl then
      dbms_output.put_line( 'Syntax not proper format. Expecting:');
      dbms_output.put_line( '<action> <group> <object-type> <object-name> ....');
      dbms_output.put_line( substr( clean_txt, 1, 100 ) );
  end "_decode";

  procedure "_fetch"( txt in out nocopy clob, p in out nocopy cSQL.syntax_parser_t )
  as
    act  varchar2(200);
    grp  varchar2(200);
    obj  varchar2(200);
  begin
    "_decode"( txt, act, grp, obj );

    p := new cSQL.syntax_parser_t( act, grp, obj );
    null;
  end;

  procedure "_transpile"( txt in out nocopy clob, j in out nocopy JSON )
  as
     p  syntax_parser_t;
  begin
    "_fetch"( txt, p );
    null;
  end "_transpile";

  -- procedure "_assert"( txt in out nocopy clob );


  /* ensures `txt` picks the correct object */
  procedure fetch_object( txt in clob )
  as
    p    cSQL.syntax_parser_t;
    act  varchar2(200);
    grp  varchar2(200);
    obj  varchar2(200);

    clean_txt  clob;
  begin
    "_decode"( txt, act, grp, obj);

    dbms_output.put_line( 'Decode: act="' || act || '" grp="' || grp || '" obj="' || obj || '"' );

    p := new cSQL.syntax_parser_t( act, grp, obj );
    if p.is_saved
    then
      dbms_output.put_line( 'Found!' );
    else
      dbms_output.put_line( 'NOT FOUND' );
    end if;
  end fetch_object;


  /* fetch  parse DDL.
     output is JSON of parsed DDL
    */
  procedure parse_string( txt in clob )
  as
    act  varchar2(200);
    grp  varchar2(200);
    obj  varchar2(200);

    p    cSQL.syntax_parser_t;
    j    json;

    syntax_not_found exception;
  begin
    "_decode"( txt, act, grp, obj);
    p := new cSQL.syntax_parser_t( act, grp, obj );

    if p.is_saved
    then
      dbms_output.put_line( 'JSON of DDL' );
      j := p.transpile( txt );

      dbms_output.put_line( json_serialize( j pretty ) );
    else
      raise syntax_not_found;
    end if;

  exception
    when syntax_not_found then
      dbms_output.put_line( 'Syntax Not Found!');
      cSQL.ddlt_inspector.fetch_object( txt );
      raise;
  end parse_string;

  /* fetch,parse, and asserts DDL */
  procedure validate_ddl( txt in clob )
  as
    act  varchar2(200);
    grp  varchar2(200);
    obj  varchar2(200);

    p    cSQL.syntax_parser_t;
    j    json;

    syntax_not_found exception;
    bad_options      exception;
  begin
    "_decode"( txt, act, grp, obj);
    p := new cSQL.syntax_parser_t( act, grp, obj );

    if p.is_saved
    then
      j := p.transpile( txt );

      dbms_output.put_line( 'Attempting to validate ... ' );
      begin
        p.assert_parsed( j );
        dbms_output.put_line('Validation Successfull ');
      EXCEPTION
        when others then
          raise bad_options;
      end;
    else
      raise syntax_not_found;
    end if;

  exception
    when bad_options then
      dbms_output.put_line( 'Validation Failed!');
      dbms_output.put_line( 'Checking Parsed JSON Results');
      cSQL.ddlt_inspector.parse_string( txt );
    when syntax_not_found then
      cSQL.ddlt_inspector.fetch_object( txt );
      raise;
  end validate_ddl;

  /* builds all code then displays them
  
     null/zero `code_index` shows all
     out-of-bound `code_index` shows error
  */
  procedure build_clob( txt in clob, code_index in pls_integer default null )
  as
    act  varchar2(200);
    grp  varchar2(200);
    typ  varchar2(200);

    obj    cSQL.syntax_parser_t;
    j      JSON;
    output CLOB;
  BEGIN
    "_decode"( txt, act, grp, typ);
    obj := new cSQL.syntax_parser_t( act, grp, typ );
    -- DBMS_OUTPUT.PUT_LINE( 'matching "' || obj.match_string || '"' );
    -- DBMS_OUTPUT.PUT_LINE( 'matching "' || obj.syntax_action || '"' );
    -- dbms_output.put_line( sql_texts( sql_key_acl)  );
    
    j := obj.transpile( txt );

    if j is null THEN
      dbms_output .put_line( 'j is null');
      RAISE_APPLICATION_ERROR(-20999, 'did not parse code (null tokens)');
    else
      dbms_output.put_line( json_serialize(j));
      dbms_output.put_line( obj.execution_snippets(1) );
      output := obj.build_code( j );
    end if;


    dbms_output.PUT_LINE( '----' );
    dbms_output.put_line( output );
  end build_clob;
end;
/
