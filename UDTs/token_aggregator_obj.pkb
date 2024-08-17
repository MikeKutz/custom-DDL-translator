create or replace
type body token_aggregator_obj
as
    constructor function token_aggregator_obj return self as result
    as
        j json_object_t := new json_object_t();
    begin
        json_txt := j.to_string;
        aggregator_pk := token_aggregator_seq.nextval;
        lvl  := 1;
        is_sub := 0;
        work_state := cSQL.token_aggregator_globals.work_on_self;

        return;
    end;

    member procedure new_ref_obj( self in out nocopy token_aggregator_obj, p_lvl in int )
    as
        v token_aggregator_obj;
    begin
        v        := new token_aggregator_obj();

        v.lvl := v.lvl + nvl( nullif( p_lvl, 0 ), 0);
--        dbms_output.put_line( ' -- new obj lvll=' || v.lvl || ' build='||is_sub);

        insert into token_aggregators p
        values v
        returning ref(p) into sub_json;

    end;

    member function iterate_step( self in out nocopy token_aggregator_obj, t in tokens_t ) return int
    as
        err_code int;
        v      token_aggregator_obj;  -- deref sub object
        j      json_object_t; -- sub object json_txt
        k      json_array_t;  -- sub object temp_array
        s      json_object_t; -- self json_txt

        procedure log_info( p_step in varchar2 default null)
        as
        begin
            null;
--            dbms_output.put_line( '("' || t.match_class || '","' || t.token || '",' || lvl || ':sub =' || is_sub || ') -> ' || p_step );
        end;

    begin

        case is_sub
            when cSQL.token_aggregator_globals.p2s_no then
                err_code := self_iterator(t);
            when cSQL.token_aggregator_globals.p2s_yes then
                err_code := sub_iterator(t);
            else
                raise no_data_found;
        end case;

        save_self;
        return err_code;

        return 0;
    end;

    member procedure save_self
    as
    begin
        update token_aggregators a
          set a.json_txt   = self.json_txt,
              a.temp_string = self.temp_string,
              a.temp_array  = self.temp_array,
              a.sub_json   = self.sub_json,
              a.is_sub      = self.is_sub,
              a.current_name = self.current_name,
              a.work_state   = self.work_state
        where a.aggregator_pk = self.aggregator_pk
        ;
    end;

    member function self_iterator( self in out nocopy token_aggregator_obj, t in tokens_t ) return int
    as
        err_code int;
        v      token_aggregator_obj;  -- deref sub object
        j      json_object_t; -- sub object json_txt
        k      json_array_t;  -- sub object temp_array
        s      json_object_t; -- self json_txt

        cg    varchar2(1);  -- classification group
        temp  varchar2(50); -- buffer value

        procedure log_info( p_step in varchar2 default null)
        as
        begin
            null;
--            dbms_output.put_line( '("' || t.match_class || '","' || t.token || '",' || lvl || ':sub =' || is_sub || ') -> ' || p_step );
        end;

    begin
        /*
            TOP LEVEL BASED ON t.mc (match classification)
            w_*     : no-op
            n_*     : json key (set current_name)
            o_*     : json value ( append key:value to json_txt )
            e_*     : expression ( append value || ' ' to temp_string )
            l_*     : list item ( append value to temp_array )
            x_*     : binary setting ( append key:value where key is substrin( t.mc, 3 ) )
            c_*     : control character; change internal state (see other list)
            *       : all else are no-op (log error)


            c_comma            : no-op
            c_obj_comma        : return work_on_sub_obj
            c_start_exp        : work_state := work_on_exp
                               : new sub; is_sub := p2s_yes
                               : sub.work_state := work_on_exp; sub.save_self
            c_start_list       : work_state := work_on_array
                               : new sub; is_sub := p2s_yes
                               : sub.work_state := work_on_list; sub.save_self
            c_start_obj        : set work_state := work_on_sub_object
                               : new sub; is_sub := p2s_yes
                               : sub.work_state := work_on_self; sub.save_self
            c_start_obj_array  : work_state := work_on_sub_object_array
                               : temp_array := null
                               : create sub; is_sub := p2s_yes

            c_end_list          : error
            c_end_obj           : error
            c_end_obj_array     : error



        */
        if not regexp_like( t.match_class, '^[[:alpha:]]_')
        then
            log_info( 'not a X_%');
            -- log error
            return 0;
        end if;

        cg := lower(substr( t.match_class, 1, 1));

        case cg
            when 'w' then
                log_info( 'w_% --> no-op' );
                -- no-op
                return 0;
            when 'n' then
                -- json name
                current_name := t.token;
                log_info( 'n_% --> current_name="' || current_name || '"  length(json_txt)=' || length(json_txt) );
            when 'o' then
                -- json value
                ddlt_util.append_key_string( json_txt, coalesce( current_name, substr(3,t.match_class), 'atr'), t.token );
                log_info( 'o_% --> key="' || current_name || '" : value="' || t.token || '"  length(json_txt)=' || length(json_txt) );

            when 'e' then
                -- expression
                temp_string := temp_string || t.token || ' ';
            when 'x' then
                -- binary
                ddlt_util.append_key_string( json_txt, nvl( substr(t.match_class,3), 'bin'), t.token );
            when 'l' then
                -- array string
                ddlt_util.append_array_string( temp_array, t.token );
            when 'c' then
                -- control character : process accordingly
                case lower( substr( t.match_class, 3 ) )
                    when 'comma' then
                        -- no-op
                        return 0;
                    when 'obj_comma' then
                        -- done with this object
                        return cSQL.token_aggregator_globals.work_on_sub_object;
                    when 'start_list' then
                        work_state := cSQL.token_aggregator_globals.work_on_array;
                        temp_array := null;
                    when 'start_exp' then
                        work_state := cSQL.token_aggregator_globals.work_on_expression;
                        temp_string := null;
--                        new_ref_obj( lvl );
--                        is_sub := 1;
--                        -- sub_json.work_state := cSQL.token_aggregator_globals.work_on_expression;
--                        -- sub_json.save_self
                    when 'start_obj' then
                        new_ref_obj( lvl );
                        is_sub := 1;
                        work_state := cSQL.token_aggregator_globals.work_on_sub_object;
                    when 'start_obj_array' then
                        temp_array := null;
                        new_ref_obj( lvl );
                        is_sub := 1;
                        work_state := cSQL.token_aggregator_globals.work_on_sub_object_array;
                        log_info( 'starting new object array length(json_text)=' || length(json_txt));
                    when 'end_obj_array' then
                        return cSQL.token_aggregator_globals.work_on_sub_object_array;
                    when 'end_exp' then
                        -- i'm done working on an Expression
                        ddlt_util.append_key_string( json_txt, nvl( current_name, 'exp' ), trim(temp_string) );
                        work_state := cSQL.token_aggregator_globals.work_on_self;
                        return 0;
                    when 'end_list' then
                        -- i'm working on an Array
                        ddlt_util.append_key_array( json_txt, nvl( current_name, 'arr' ), temp_array );
                        work_state := cSQL.token_aggregator_globals.work_on_self;
                        return 0;
                    when 'end_obj' then
                        return cSQL.token_aggregator_globals.work_on_sub_object;
                    else
                        log_info( 'BAD c_% -- ' || t.match_class );

                end case;

            else
                case work_state
                    when cSQL.token_aggregator_globals.work_on_expression then
                        temp_string := temp_string || t.token || ' ';
                    when cSQL.token_aggregator_globals.work_on_array then
                        ddlt_util.append_array_string( temp_array, t.token );
                    else
                        null;
                end case;
                null;
        end case;

        save_self;
--        dbms_output.put_line( '      --->' || json_txt );
        return 0;

/*        case
            when is_sub != 0 then
                err_code := sub_iterator(t);
            when is_sub = 0 and t.match_class in ( upper('c_start_list'), upper('c_start_obj'),upper('c_start_obj_array')) then
                log_info( 'start of list/obj' );
                self.is_sub := case t.match_class
                                    when upper('c_start_list') then 1
                                    when upper('c_start_obj') then 2
                                    when upper('c_start_obj_array') then 3
                                    else -1
                                end;
                new_ref_obj( lvl );
            when t.match_class in (upper('c_end_list'), upper('c_end_obj'), upper('c_end_obj_array')) then
                log_info( 'end of list' );
                return case t.match_class
                            when upper('c_end_list') then 1
                            when upper('c_end_obj') then 2
                            when upper('c_end_obj_array') then 3
                            else -1
                        end;
            when t.match_class in (upper('c_comma'), upper('c_obj_comma') ) then
                log_info( 'comma (skip)' );
                null;
            when t.match_class like upper('n_%') then
                log_info( 'json key "' || t.token || '"' );
                current_name := t.token;
            when t.match_class like upper('o_%') then
                log_info( 'json value (' || current_name || ','|| t.token || ')' );
                j.put( current_name, t.token );
                json_txt := j.to_string();
                current_name := null;
            when t.match_class like upper('l_%') then
                log_info( 'array element (list = "' || t.token || '")' );
                if temp_array is null
                then
                    k := new json_array_t();
                else
                    k := new json_array_t(temp_array);
                end if;
                k.append( t.token );

                temp_array := k.to_clob();
            when t.match_class like upper('%_clause') then
                log_info( 'code clause' );
--                j := json_obj_t.parse( json_txt );
                temp_string := temp_string || t.token || ' ';
            when t.match_class like upper('w_%') then
                log_info( 'static word' );
                -- append this value
--                j.put( t.match_class, t.token );
--                json_txt := j.to_clob;
--                json_txt := json_object( t.match_class value t.token );
            else
                log_info( 'not found' );
                null;
        end case;

        json_txt := j.to_clob();

        save_self;
--        dbms_output.put_line( '      --->' || json_txt );
        return 0;
        */
    end;

    member function sub_iterator ( self in out nocopy token_aggregator_obj, t in tokens_t ) return int
    as
        err_code int;
        v       token_aggregator_obj;
        j      json_object_t := json_object_t(  );
        k      json_array_t := new json_array_t();
        s       json_object_t;

        procedure log_info( p_step in varchar2 default null)
        as
        begin
            null;
--            dbms_output.put_line( '("' || t.match_class || '","' || t.token || '", level=' || lvl || ':sub =' || is_sub || ') -> ' || p_step || ' jl=' || length(json_txt));
        end;
    begin
        select deref(sub_json)
            into v
        from dual;

        err_code := v.iterate_step( t );
        log_info('sub_log interator = ' || err_code );

        case err_code
            when cSQL.token_aggregator_globals.work_on_self then
                return 0;
            when cSQL.token_aggregator_globals.work_on_expression then
                -- sub object is finished creating expression
                if work_state = cSQL.token_aggregator_globals.work_on_sub_object
                then
                    ddlt_util.append_key_string( json_txt,  nvl(current_name,'exp'), v.temp_string );

                    is_sub     := cSQL.token_aggregator_globals.p2s_no;
                    work_state := cSQL.token_aggregator_globals.work_on_self;
                    return 0;
                end if;

                log_info( 'expecting state = ' || cSQL.token_aggregator_globals.work_on_self || ' : actual state = ' || work_state );
                raise cSQL.ddlt_errors.general_error;
            when cSQL.token_aggregator_globals.work_on_array then
                -- sub object is finished creating array
                if work_state = cSQL.token_aggregator_globals.work_on_sub_object
                then
                   -- append string buffer put( current_name, sub.temp_array )
                   ddlt_util.append_key_array( json_txt, nvl(current_name,'arr'), v.temp_array );
                    is_sub     := cSQL.token_aggregator_globals.p2s_no;
                    work_state := cSQL.token_aggregator_globals.work_on_self;
                    return 0;
                end if;

                log_info( 'expecting state = ' || cSQL.token_aggregator_globals.work_on_self || ' : actual state = ' || work_state );
                raise cSQL.ddlt_errors.general_error;
            when cSQL.token_aggregator_globals.work_on_sub_object then
                -- sub object is finished creating object
                log_info( ' -- building object work_state=' || work_state );
                case work_state
                    when cSQL.token_aggregator_globals.work_on_sub_object then
                        -- and we're adding key:object
                        ddlt_util.append_key_object( json_txt, nvl(current_name,'obj'), v.json_txt );

                        is_sub     := cSQL.token_aggregator_globals.p2s_no;
                        work_state := cSQL.token_aggregator_globals.work_on_self;
                        return 0;
                    when cSQL.token_aggregator_globals.work_on_sub_object_array then
                        -- and we're appending object to array
                        ddlt_util.append_array_object( temp_array, v.json_txt );
                        -- MISSING !!
--                         v.clean_self; -- implies v.self_save
                        return 0;
                    else
                        log_info('blah');
                        raise cSQL.ddlt_errors.general_error;
                end case;
            when cSQL.token_aggregator_globals.work_on_sub_object_array then
                -- sub object is finished making object
                --    and tells us we're done with making our array

                -- append sub object to array
                -- append key:array to self
                ddlt_util.append_array_object( temp_array, v.json_txt );
                ddlt_util.append_key_array( json_txt, nvl( current_name, 'arrObj'), temp_array );


                is_sub     := cSQL.token_aggregator_globals.p2s_no;
                work_state := cSQL.token_aggregator_globals.work_on_self;
                return 0;
            else
                log_info( 'uncaught error = ' || err_code || ' : current state = ' || work_state);
        end case;

        return err_code;
/** old 
                if err_code != 0 
                then
                    if t.token != upper('c_end_obj_array')
                    then
                        case is_sub -- list, obj, array -- i am building
                            when 1 then
                                if v.temp_string is not null
                                then
        --                        dbms_output.put_line( '   !! end of expression');
                                    j.put( nvl(current_name,'expression'), v.temp_string );
                                end if;

                                if v.temp_array is not null
                                then
        --                        dbms_output.put_line( '   !! end of array');
                                    k := json_array_t( v.temp_array );
                                    j.put( nvl(current_name,'list'), k );
                                end if;
                            when 2 then
                                if is_sub = 3
                                then
                                dbms_output.put_line( '   !! end of object -- appending');
                                    if temp_array is null
                                    then
                                        k := new json_array_t;
                                    else
                                        k := json_array_t( temp_array );
                                    end if;
                                    k.append( json_object_t( v.json_txt ) );
                                    temp_array := k.to_clob;
                                else
                                dbms_output.put_line( '   !! end of object -- applying to last');

                                    j := json_object_t( v.json_txt );
                                    j.put( nvl(current_name,'obj'), j );
                                end if;
                            when 3 then
                                if err_code = 2 then
                                    dbms_output.put_line( '   !! end of object array');
                                    if temp_array is null
                                    then
                                        k := new json_array_t;
                                    else
                                        k := json_array_t( temp_array );
                                    end if;

                                    k.append( json_object_t( v.json_txt ) );
                                elsif err_code = 3 then
                                    dbms_output.put_line( '   !! end of BUILD ARRAY');
                                else
                                    dbms_output.put_line( '   !! end of NOT AN OBJECT');
                                end if;
                            else
                                dbms_output.put_line( '   !! end of ERROR');
                        end case;
                    else
                        j := json_object_t( v.json_txt );
                        if temp_array is null
                        then
                            k := new json_array_t;
                        else
                            k := json_array_t( temp_array );
                        end if;

                        j.put( nvl(current_name,'objarr'), k );

                    end if;
                    is_sub := 0;

                    json_txt := j.to_clob; -- v.temp_string;
                    current_name := null;
                end if;

    */
    end;
end;
