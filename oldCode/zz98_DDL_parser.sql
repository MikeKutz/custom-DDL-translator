create or replace
package ddl_parser
as
--  function get_tokens(  txt in clob ) return dbms_sql.
  function  normalize_code( txt in clob ) return clob;
  function convert2tree( txt in clob ) return xmltype;
end;
/

create or replace
package body ddl_parser
as
--  function get_tokens(  txt in clob ) return dbms_sql.
  function  normalize_code( txt in clob ) return clob
  as
    ret_value clob := txt;
  begin
    --   remove comments
    ret_value := regexp_replace(  txt , '--.*$', ' ', 1,  0, 'm' );

    --  make 1 line
    ret_value  := regexp_replace(  ret_value, chr(10), ' ' );
    

    ret_value  := regexp_replace(  ret_value, '([\(\),]|=>)', ' \1  ' );

    -- sinle spaces
    while (regexp_like( ret_value, '  ' )  )
    loop
      ret_value  := regexp_replace(  ret_value, '  ', ' ' );
    end loop;
    
    return trim(ret_value);
  end;
  
  function convert2tree( txt in clob ) return xmltype
  as
    tmp_clob clob := txt;
    ret_value xmltype;
  begin
    tmp_clob := regexp_replace( txt, ' ', '</token><token>' );
    tmp_clob := to_clob( '<cmd><token>' ) || tmp_clob ||  to_clob( '</token></cmd>');
    
    return xmltype( tmp_clob );
  end;
  
  
  
end;
/

create or  replace
package app_acl_processor
as
    type acl_head_t  is record ( acl_name varchar2(50), sec_class varchar2(50) );
        type ace_priv_tt is record ( principal varchar2(50), privilege_item varchar2(50) );
        type ace_priv_nt is table of  ace_priv_tt;
        
    type ace_priv_t is  table  of  varchar2(50);
    type aces_t is record ( principal varchar2(50), privilege_list ace_priv_t );
    type aces_nt is table of aces_t;
    
    function get_acl_head( txt in clob ) return acl_head_t;
    function get_aces( txt in clob ) return aces_nt;
    function gen_code( acl in acl_head_t, aces in aces_nt ) return clob;
    function proces_command(  txt in clob ) return clob;
end;
/

create or  replace
package body app_acl_processor
as
    function get_acl_head( txt in clob ) return acl_head_t
    as
        ret_val acl_head_t;
    begin
        with tokens_list as (
            select x.*
            from xmltable( '/cmd/token'
              passing ddl_parser.convert2tree(ddl_parser.normalize_code(txt))
              columns
                rn    for ORDINALITY,
                token varchar2(50) path '/token'
            )  x
        )
        select *
         into ret_val
        from tokens_list
        MATCH_RECOGNIZE (
           order  by rn
            MEASURES
                first(obj_name.token) as acl_name,
                first(obj_name.token,1) as sec_name
            pattern ( w1 w2  w3 obj_name w4 w5 w6 obj_name w7 w8  start_list obj_name hash_code start_list obj_name* end_list  end_list )
            DEFINE
                w1   as token = 'create',
                w2   as token = 'application',
                w3   as token = 'acl',
                w4   as token = 'for',
                w5   as token = 'security',
                w6   as token = 'class',
                w7   as token = 'having',
                w8   as token  = 'aces',
                start_list  as  token = '(',
                end_list  as  token = ')',
                hash_code as token  =  '=>',
                obj_name  as 1=1
                
        );
        
        return  ret_val;
    end;
    
    function get_aces( txt in clob ) return aces_nt
    as
        ret_val     aces_nt := aces_nt();
        aces_privs  ace_priv_nt;
        empty_list  ace_priv_t := ace_priv_t();
    begin
         with tokens_list as (
            select x.*
            from xmltable( '/cmd/token'
              passing ddl_parser.convert2tree(ddl_parser.normalize_code(txt))
              columns
                rn    for ORDINALITY,
                token varchar2(50) path '/token'
            )  x
        )
       select  distinct principal,  privilege_item
         bulk collect into aces_privs
        from tokens_list
        MATCH_RECOGNIZE (
           order  by rn
            MEASURES
                first(obj_name.token) as principal,
                obj_name.token as privilege_item
            all rows per MATCH
        
            pattern ( start_list* obj_name hash_code  start_list obj_name (comma_code obj_name)* end_list )
            define
                start_list  as  token = '(',
                end_list  as  token = ')',
                hash_code as token  =  '=>',
                comma_code as token = ',',
                obj_name  as 1=1
        )
        where  principal != privilege_item
        order by principal;
    
        declare
            current_principal varchar2(50) := 'not a name';
            i  int := 0;
            j  int := 0;
        begin
            for rec in (select * from table(aces_privs))
            loop
                if current_principal != rec.principal
                then
                    ret_val.extend(1);
                    i := i + 1;
                    j := 0;
                    ret_val(i).principal :=  rec.principal;
                    ret_val(i).privilege_list := empty_list;
                    current_principal := rec.principal;
                end if;
                
                ret_val(i).privilege_list.extend(1);
                j := j +  1;
                ret_val(i).privilege_list(j)  := rec.privilege_item;
            end loop;
        end;
    
    
        return ret_val;
    end;
    
    function gen_code( acl in acl_head_t, aces in aces_nt ) return clob
    as
        ret_val clob;
        n_aces  int;
    begin
        n_aces  := aces.count;
        
--        return null;
        
        ret_val := q'[declare
          aces xs$ace_list := xs$ace_list();  
begin 
  aces.extend(]' || n_aces || q'[);
  
]';

    for i in  1 .. n_aces
    loop
        ret_val  := ret_val ||  q'[
         aces(]' || i || q'[) := xs$ace_type(privilege_list => xs$name_list(]';
        
        for  j in 1 .. aces(i).privilege_list.count
        loop
            ret_val := ret_val || case when  j  <> 1 then ',''' else '''' end  || aces(i).privilege_list(j) || '''';
        end loop;
        
        ret_val := ret_val || q'[),
                             principal_name => ']' || aces(i).principal  || q'['); ]';
    end loop;
    
 
        
        
        ret_val := ret_val || q'[
        
        sys.xs_acl.create_acl( name  =>  ']' || acl.acl_name || q'[',
                               sec_clas => ']' || acl.sec_class || q'[',
                               ace_list => aces );
end;
]';
        
        return ret_val;
    end;

    procedure do_work(  acl in acl_head_t, aces in aces_nt  )
    as
        code_ace xs$ace_list := xs$ace_list();
        priv_list xs$name_list;
        empty_priv_list xs$name_list := xs$name_list();
        
    begin
    
        code_ace.extend( aces.count );
    
        dbms_output.put_line( 'creating acl "' || acl.acl_name || '" for "' || acl.sec_class ||'"' );
    
        for i in 1 .. aces.count
        loop
            dbms_output.put_line( ' ' || aces(i).principal );


            priv_list :=  empty_priv_list;
            
            for j in 1 ..   aces(i).privilege_list.count
            loop
               priv_list.extend;
               priv_list(j) := aces(i).privilege_list(j);
               dbms_output.put_line( ' ...' || priv_list(j) );
            end loop;
 
            code_ace( i ) :=  xs$ace_type(  privilege_list  =>  priv_list, principal_name => aces(i).principal );
 
        end loop;

--        xs_acl.create_acl(name     => acl.acl_name,
--                         ace_list  => code_ace,
--                         sec_class => acl.sec_class);

    end;

    function proces_command(  txt in clob ) return clob
    as
        acl_main    acl_head_t;
        aces        aces_nt;
    begin
        acl_main := get_acl_head( txt );
        aces     := get_aces( txt );
        
        
        return  gen_code(acl_main, aces);
--        return acl_main.acl_name || '-' || acl_main.sec_class || ' : ' || aces.count;
    end;

end;
/

/*

*/

