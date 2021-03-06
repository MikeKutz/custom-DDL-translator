create or replace package body ddlt_util
as
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

    function parse_xml_tokens( xml_tokens in xmltype) return tokens_nt pipelined
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
            pipe row( tokens_t( null, null, rec.rn, rec.token ) );
        end loop;
    
        return;
    end;
    
/******************************************************************************/

    function always_true( n in int ) return int DETERMINISTIC
    AS
    begin
        return 1;
    end always_true;

/******************************************************************************/

    function safe_clob2json_array(txt in clob ) return json_array_t
    as
        ret_val json_array_t;
    begin
        if txt is null
        then
            ret_val := new json_array_t;
        else
            ret_val := new json_array_t(txt);
        end if;
        
        return ret_val;
    end;

/******************************************************************************/

    function safe_clob2json_object(txt in clob ) return json_object_t
    as
        ret_val json_object_t;
    begin
        if txt is null
        then
            ret_val := new json_object_t;
        else
            ret_val := new json_object_t(txt);
        end if;
        
        return ret_val;
    end;

/******************************************************************************/

    procedure append_key_string( txt in out nocopy clob, key in varchar2, string_txt in clob )
    as
        s  json_object_t;
    begin
        s := safe_clob2json_object( txt );
        s.put( key, string_txt );
        
        txt := s.to_clob;
    end;
    
/******************************************************************************/

    procedure append_key_array( txt in out nocopy clob, key in varchar2, array_txt in clob )
    as
        s  json_object_t;
        a  json_array_t;
    begin
        s := safe_clob2json_object( txt );
        a := safe_clob2json_array( array_txt );
        
        s.put( key, a );
        txt := s.to_clob;
    end;

/******************************************************************************/

    procedure append_key_object( txt in out nocopy clob, key in varchar2, object_txt in clob )
    as
        s  json_object_t;
        j  json_object_t;
    begin
        s := safe_clob2json_object( txt );
        j := safe_clob2json_object( object_txt );
        
        s.put( key, j );
        txt := s.to_clob;
    end;

/******************************************************************************/

    procedure append_array_string( txt in out nocopy clob, string_txt in varchar2 )
    as
        sa  json_array_t;
    begin

         sa := safe_clob2json_array( txt );
         sa.append( string_txt );
         
         txt := sa.to_clob;
    end;

/******************************************************************************/

    procedure append_array_object( txt in out nocopy clob, object_txt in clob)
    as
        sa  json_array_t;
        j  json_object_t;
   begin
         sa := safe_clob2json_array( txt );
         j  := safe_clob2json_object(object_txt);

         sa.append( j );
         
         txt := sa.to_clob;
    end;

/******************************************************************************/

    procedure  append_array_array( txt in out nocopy clob, array_text in clob)
    as
        sa  json_array_t;
        a  json_array_t;
    begin
         sa := safe_clob2json_array( txt );
         a := safe_clob2json_array( array_text );
         
         sa.append( a );
         
         txt := sa.to_clob;
    end;
    
/******************************************************************************/
    
    /* convert PATTERN into list of unique keys */
    function pattern_to_definition_keys( txt in clob ) return mr_keys
    as
        ret_val mr_keys := new mr_keys();
    begin
        -- tokenize PATTERN
        -- keep only REGEXP_LIKE( token, '^[[:alpha:]]')
        select distinct a.token
            bulk collect into ret_val
        from table(parse_xml_tokens(convert2tree( normalize_code(txt)))) a
        where  REGEXP_LIKE( token, '^[[:alpha:]]');
        
        return ret_val;
    end;

/******************************************************************************/
    /* builds the DEFINE clause of a MATCH_RECOGINZE statement
    *
    * 
    * @param pattern_txt        actual PATTERN clause
    * @param definition_clause  additional DEFINE clause elements
    * @return complete DEFINITION clause that meets the needs of the give PATTERN clause
    */
    function build_define_clause( pattern_txt in clob, definition_hash in mr_define_exp_hash) return clob
    as
        ret_val clob;
        pat_keys mr_keys := mr_keys();
        com_keys mr_keys := mr_keys();
        def_keys mr_keys := mr_keys();
        
        needed_keys mr_keys := mr_keys();
        final_hash mr_define_exp_hash;
        
        i int := 0;
        tv varchar2(50);
    begin
        def_keys := keys_to_array(definition_hash);
        com_keys := keys_to_array(mr_standard_def);
--        pat_keys := pattern_to_definition_keys( pattern_txt );

        -- fix keys ( remove * + ? *? +? )
        for k in values of pattern_to_definition_keys( pattern_txt )
        loop
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
                when mr_standard_def.exists( val ) then
                    final_hash( val ) := mr_standard_def( val );
                else
                    null;
                    final_hash( val ) := '1=ddlt_util.always_true(' || (i+100) || ')';
            end case;
        end loop;
        
        return define_hash_to_clause(final_hash);
    end;
    
/******************************************************************************/
    /* converts a hash of define into actual DEFINE clause
    *  no alterations are done 
    *
    *  @param def_hash hash of values to be converted
    *  @return text representing DEFINE clause of MATCH_RECOGNIZE
    */
    function define_hash_to_clause( def_hash in mr_define_exp_hash ) return clob
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
    end;

/******************************************************************************/

    function keys_to_array( def_hash in mr_define_exp_hash ) return mr_keys
    as
        ret_val mr_keys := new mr_keys();
    begin
        for k in indices of def_hash
        loop
             ret_val.extend(1);
             ret_val( ret_val.last ) := k;
        end loop;
        
        return ret_val;
    end;
    
    function build_mr( pattern_txt in clob, definition_txt in clob) return clob
    as
        ret_val clob;
    begin
        ret_val := q'[
select *
from DDLT_TOKENS_TAMP --p_var
match_recognize (
    order by rn
    measure
        ???
    all rows per match
    pattern (
        #PATTERN#
    )
    define
    #DEFINE#
) abc]';

        ret_val := replace(replace( ret_val, '#PATTERN#', pattern_txt ), '#DEFINE#', definition_txt );
        
        return ret_val;
    end;
    
    function build_dyna_mr(pattern_txt in clob, definition_txt in clob) return clob
    as
        ret_val clob;
    begin
        ret_val :=q'[
declare
    r tokens_nt;
    n tokens_nt;
begin
    n := :tokens;
    
    select tokens_t(a.mn, a.mc, a.rn, a.token)
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

--    r := tokens_nt( tokens_t(1, 2,3,4 ) );
                
    :result := r;
end; ]';

            ret_val := replace( ret_val, '&1',  pattern_txt );
            ret_val := replace( ret_val, '&2', definition_txt );

        return ret_val;
    end;

    function mr( p_tab dbms_tf.table_t, pattern_txt in clob, deinition_txt in clob)
          return varchar2 sql_macro(table)
    as
    begin
      return q'{
        select null mn, null mc, pattern_txt rn, deinition_txt token
        from dual
      }';
    end;

    function pattern_parser( statement_txt in clob, pattern_txt in clob, custom_dev in mr_define_exp_hash, sql_txt out clob, run_sql boolean default true ) return tokens_nt
    as
        definition_txt clob;
        tokens         tokens_nt := new tokens_nt();

        txt      clob;
        c        integer;
        err_code int;

        ret_val   tokens_nt := new tokens_nt();
    begin
        -- build the tokens from the Statement
        select tokens_t( null,null,rn,token)
            bulk collect into tokens
        from table(parse_xml_tokens(convert2tree( normalize_code(statement_txt)))) a;
        
        -- Pattern is used AS-IS

        -- build the correct Definition
        definition_txt := build_define_clause( pattern_txt, custom_dev );
       
        txt := build_dyna_mr( pattern_txt, definition_txt);
        sql_txt := txt;


        -- NOTE: ORA-600 workaround
        -- pattern match against DDLT_TOKENS_TEMP
        -- pull result from DDLT_MATCHED_TOKENS_TEMP
        delete from ddlt_tokens_temp;
        insert into ddlt_tokens_temp
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
    end;

end;
/
