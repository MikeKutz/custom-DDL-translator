set define off;
CREATE OR REPLACE
PACKAGE BODY PARSER_UTIL AS
  matchrecognize_standard_defines  constant matchrecognize_define_expression_hash := matchrecognize_define_expression_hash(
        'w_create'           => q'[token = 'create']',
        'w_alter'            => q'[token = 'alter']',
        'w_drop'             => q'[token = 'drop']',
        'c_start_list'       => q'[token = '(' and 1=ddlt_util.always_true(1001)]',
        'c_end_list'         => q'[token = ')' and 1=ddlt_util.always_true(1002)]',
        'c_comma'            => q'[token = ',' and 1=ddlt_util.always_true(1003)]',
        'c_start_exp'        => q'[token = '(' and 1=ddlt_util.always_true(1004)]',
        'c_end_exp'          => q'[token = ')' and 1=ddlt_util.always_true(1005)]',
        'c_start_obj'        => q'[token = '(' and 1=ddlt_util.always_true(1006)]',
        'c_end_obj'          => q'[token = ')' and 1=ddlt_util.always_true(1007)]',
        'c_start_obj_array'  => q'[token = '(' and 1=ddlt_util.always_true(1008)]',
        'c_end_obj_array'    => q'[token = ')' and 1=ddlt_util.always_true(1009)]',
        'c_obj_comma'        => q'[token = ',' and 1=ddlt_util.always_true(1010)]',
        'c_semi'             => q'[token = ';' and 1=ddlt_util.always_true(1011)]',
        'c_hash'             => q'[token = ';' and 1=ddlt_util.always_true(1012)]'
    );
    

  function  normalize_code( txt in clob ) return clob
  as
      ret_value clob := txt;
  begin
      --   remove comments
      ret_value := regexp_replace(  txt , '--.*$', ' ', 1,  0, 'm' );
      
      --  make 1 line
      ret_value  := replace(  ret_value, chr(10), ' ' );
      ret_value  := replace(  ret_value, chr(13), ' ' );
      ret_value  := replace(  ret_value, chr(9), ' ' );
      
      
      -- doesn't work?
      ret_value  := regexp_replace(  ret_value, '([\(\),\|]|=>)', ' \1  ' );
      
      -- sinle spaces
      while (regexp_like( ret_value, '  ' )  )
      loop
        ret_value  := regexp_replace(  ret_value, '  +', ' ' );
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

  function parse_xml_tokens( xml_tokens in xmltype) return cSQL.tokens_nt pipelined
  as
  begin
      for rec in (
          select rn, token
          from xmltable ( '/cmd/token'
              passing xml_tokens
              columns
                  rn for ordinality,
                  token varchar2(50) path '/'
              )
          )
      loop
          pipe row( cSQL.tokens_t( null, null, rec.rn, rec.token ) );
      end loop;
  
      return;
  end parse_xml_tokens;

/******************************************************************************/

    /* convert PATTERN into list of unique keys */
    function pattern_to_definition_keys( txt in clob ) return matchrecognize_keys
    as
        ret_val matchrecognize_keys := new matchrecognize_keys();
    begin
        -- tokenize PATTERN
        -- keep only REGEXP_LIKE( token, '^[[:alpha:]]')
        select distinct a.token
            bulk collect into ret_val
        from table(parse_xml_tokens(convert2tree( normalize_code(txt)))) a
        where  REGEXP_LIKE( token, '^[[:alpha:]]');
        
        return ret_val;
    end pattern_to_definition_keys;

/******************************************************************************/

    /* builds the DEFINE clause of a MATCH_RECOGINZE statement
    *
    * 
    * @param pattern_txt        actual PATTERN clause
    * @param definition_clause  additional DEFINE clause elements
    * @return complete DEFINITION clause that meets the needs of the give PATTERN clause
    */
    function build_define_clause( pattern_txt in clob, definition_hash in matchrecognize_define_expression_hash) return clob
    as
        ret_val      clob;
        pat_keys     matchrecognize_keys := matchrecognize_keys();
        com_keys     matchrecognize_keys := matchrecognize_keys();
        def_keys     matchrecognize_keys := matchrecognize_keys();
        
        needed_keys  matchrecognize_keys := matchrecognize_keys();
        final_hash   matchrecognize_define_expression_hash;
        
        i            int := 0;
        tv           varchar2(50); -- ??
    begin
        def_keys := keys_to_array(definition_hash);
        com_keys := keys_to_array(matchrecognize_standard_defines);
--        pat_keys := pattern_to_definition_keys( pattern_txt );

        -- fix keys ( remove * + ? *? +? )
        for k in values of pattern_to_definition_keys( pattern_txt )
        loop
            /*
              tv := k;
              fix(tv);
              assert(tv);
            */
            tv := replace(k,'+','');
            tv := replace(tv,'*','');
            tv := replace(tv,'?','');
            tv := replace(tv,'+?','');
            tv := replace(tv,'*?','');
            tv := replace(tv,'|','');
            
            -- skip if tv IS NULL
--            continue when tv is null;
            
            pat_keys.extend;
            pat_keys( pat_keys.last ) := nvl(tv, '1=0');
         end loop;
        

    
        -- needed com := pat_keys intersect com_keys
        -- pat_keys union (pa
        needed_keys := (pat_keys multiset intersect com_keys) multiset union pat_keys;
        
        for val in values of needed_keys
        loop
            i := i + 1;
            case
                when definition_hash.exists( val ) then
                    final_hash( val ) := definition_hash( val );
                when matchrecognize_standard_defines.exists( val ) then
                    final_hash( val ) := matchrecognize_standard_defines( val );
                else
                    null;
                    final_hash( val ) := '1=ddlt_util.always_true(' || (i+100) || ')';
            end case;
        end loop;
        
        return define_hash_to_clause(final_hash);
    end build_define_clause;

/******************************************************************************/

  /* converts a hash of define into actual DEFINE clause
  *  no alterations are done 
  *
  *  @param def_hash hash of values to be converted
  *  @return text representing DEFINE clause of MATCH_RECOGNIZE
  */
  function define_hash_to_clause( def_hash in matchrecognize_define_expression_hash ) return clob
  as
      ret_val clob;
      n int := def_hash.count;
      i int := 0;
  begin
      for k,v in pairs of def_hash
      loop
          i := i + 1;
          ret_val := ret_val ||
'                        ' || k || ' as ' || v || case when i != n then ',' end || chr(10);
      end loop;
      
      return ret_val;
  end define_hash_to_clause;

/******************************************************************************/

  function keys_to_array( def_hash in matchrecognize_define_expression_hash ) return matchrecognize_keys
  as
      ret_val matchrecognize_keys := new matchrecognize_keys();
  begin
      for k in indices of def_hash
      loop
           ret_val.extend(1);
           ret_val( ret_val.last ) := k;
      end loop;
      
      return ret_val;
  end keys_to_array;

/******************************************************************************/

    function build_dyna_mr(pattern_txt in clob, definition_txt in clob) return clob
    as
        ret_val clob;
    begin
        ret_val :=q'[
declare
    r cSQL.tokens_nt;
    n cSQL.tokens_nt;
begin
    n := :tokens;
    
    select cSQL.tokens_t(a.mn, a.mc, a.rn, a.token)
        bulk collect into r
    from ddlt_tokens_temp
    match_recognize (
        order by rn
        measures
            MATCH_NUMBER() as mn,
            CLASSIFIER() as mc
        all rows per match 
        pattern ( &1 )
        define
&2
                ) a;

--    r := cSQL.tokens_nt( cSQL.tokens_t(1, 2,3,4 ) );
                
    :result := r;
end; ]';

            ret_val := replace( ret_val, '&1',  pattern_txt );
            ret_val := replace( ret_val, '&2', definition_txt );

        return ret_val;
    end build_dyna_mr;

/******************************************************************************/

  function pattern_parser( statement_txt in clob
                          ,pattern_txt   in clob
                          ,custom_dev    in matchrecognize_define_expression_hash --> rename
                          ,sql_txt       out clob
                          ,run_sql       boolean default true -- what does this do?
                        ) return cSQL.tokens_nt
  as
      definition_txt clob;
      tokens         cSQL.tokens_nt := new cSQL.tokens_nt();

      txt            clob;
      c              integer;
      err_code       int;

      ret_val        cSQL.tokens_nt := new cSQL.tokens_nt();
  begin
      -- build the tokens from the Statement
      select cSQL.tokens_t( null,null,rn,token)
          bulk collect into tokens
      from table(parse_xml_tokens(convert2tree( normalize_code(statement_txt)))) a;
      
      -- Pattern clause is used AS-IS

      -- build the correct Definition clause
      definition_txt := build_define_clause( pattern_txt, custom_dev );
     
      -- build the match_recognize sql statement
      txt := build_dyna_mr( pattern_txt, definition_txt);
      sql_txt := txt;


      -- NOTE: ORA-600 workaround
      -- pattern match against DDLT_TOKENS_TEMP
      -- pull result from DDLT_MATCHED_TOKENS_TEMP
      delete from cSQL.ddlt_tokens_temp;
      insert into cSQL.ddlt_tokens_temp
      select * from table(tokens);

      if run_sql
      then
          -- do actual Dynamic SQL
          c := dbms_sql.open_cursor;
  
          begin
              null;
              DBMS_SQL.parse( c, txt, DBMS_SQL.NATIVE );
          exception
              when others then
                  dbms_sql.close_cursor( c );
                  dbms_output.put_line( 'BAD SQL !!' );
                  dbms_output.put_line(txt);
                  dbms_output.put_line( 'BAD SQL !!' );
                  raise;
          end;
  
          DBMS_SQL.BIND_VARIABLE( c, ':tokens', tokens ); -- works on UDTs
          DBMS_SQL.BIND_VARIABLE( c, ':result', ret_val ); -- works on UDTs
          err_code := DBMS_SQL.EXECUTE( c );
          DBMS_SQL.VARIABLE_VALUE( c, ':result', ret_val);
          
          dbms_sql.close_cursor( c );
      end if;
      
      return ret_val;
  exception
      when others then
              dbms_output.put_line( 'RUN TIME BAD SQL !!' );
              dbms_output.put_line(txt);
              dbms_output.put_line( 'RUN TIME BAD SQL !!' );
          dbms_sql.close_cursor( c );
          raise;
  end pattern_parser;

  function parsed_tokens_to_json( x cSQL.tokens_nt ) return JSON
  as
    ret_value               JSON;
    step_wise_interpreter   cSQL.token_aggregator_obj := new cSQL.token_aggregator_obj;
    err_code                int;
  begin
    for step in values of x
    loop
      err_code := step_wise_interpreter.iterate_step( step );
    end loop;
    
    ret_value := JSON( step_wise_interpreter.json_txt );
    
    return ret_value;
  end parsed_tokens_to_json;
  
  /* assumes all assertions are done ( see: syntax_parser_t ) */
  function generate_code_from_JSON( syntax_json JSON, code_template teJSON.Blueprint ) return clob
  as
    ret_val clob;
    
    for_inout  teJSON.Blueprint := code_template;
    e          teJSON.Engine_t;
  begin
    e := new teJSON.Engine_t( for_inout );
    ret_val := e.render_snippet( '$.run.me.now' );
    
    return ret_val;
  end generate_code_from_JSON;
-----------------------------------------------------
  function hash2aa( hash_data in MKLibrary.Hash_t ) return matchrecognize_define_expression_hash
  as
    ret_val matchrecognize_define_expression_hash;
  BEGIN
    for rec in ( select *
                 from json_table( json(hash_data.json_clob), '$.data[*]'
                    COLUMNS (
                      key_string varchar2(500) path '$.key_string',
                      val_string varchar2(500) path '$.val_string'
                    )
                 )
      
      )
    loop
      ret_val( rec.key_string ) := rec.val_string;
    end loop;

    return ret_val;
  end hash2aa;

  function aa2hash( aa_data in matchrecognize_define_expression_hash ) return MKLibrary.Hash_t
  as
    ret_val    MKLibrary.Hash_t := new MKLIBRARY.Hash_t();
    j          json_object_t    := new json_object_t();
    ja         json_array_t     := new json_array_t();
    j_element  json_object_t;
  BEGIN
    for k,v in pairs of aa_data
    loop
      j_element := new json_object_t();
      j_element.put('key_string', k );
      j_element.put('val_string', v);

      ja.append(j_element);
    end loop;

    j.put( 'data', ja );


    ret_val.json_clob := j.to_clob;
    return ret_val;
  end aa2hash;

END PARSER_UTIL;
