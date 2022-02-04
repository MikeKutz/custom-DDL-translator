set serveroutput on;
declare
    s clob;
    p clob;
    
    tt tokens_nt;
    err_code int;
    
    a token_aggregator_obj := new token_aggregator_obj;
    sql_txt clob;
begin
    s := ddlt_ras_ut.sample_policy( 5 );
    p := ddlt_ras.get_pattern( ddlt_ras.policys );
--    p := ddlt_ras.get_pattern( 'b' );
    dbms_output.put_line(s);
    dbms_output.put_line(p);
    
    tt := ddlt_util.pattern_parser( s
                                    ,p
                                    ,ddlt_ras.get_define( ddlt_ras.policys )
                                    ,sql_txt, true );

    dbms_output.put_line(sql_txt);

    delete from ddlt_matched_tokens_temp;
    insert into ddlt_matched_tokens_temp select * from table(tt);
    
    for t in values of tt
    loop
        err_code := a.iterate_step( t );
    end loop;

    dbms_output.put_line( a.json_txt );
end;
/
select * from ddlt_matched_tokens_temp;
select * from ddlt_tokens_temp;

select mn,mc,rn,token
    from ddlt_tokens_temp
    match_recognize (
        order by rn
        measures
            MATCH_NUMBER() as mn,
            CLASSIFIER() as mc
        all rows per match 
        pattern ( w_create w_application x_object_type x_object_name n_for c_start_obj_array
        (
           (x_type n_domain c_start_exp e_item+? c_end_exp n_acls c_start_list l_item (c_comma l_item)* c_end_list (c_obj_comma | c_end_obj_array) )
         | ( x_type x_privilege_name w_protects n_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list (c_obj_comma | c_end_obj_array ) )
         | ( x_type n_source_columns c_start_list l_priv (c_comma l_priv)*  c_end_list
            w_references n_table o_table n_target_columns  c_start_list l_priv (c_comma l_priv)*  c_end_list
            (n_where c_start_exp e_tok+ c_end_exp)*
        (c_obj_comma | c_end_obj_array) )
       )+ )
        define
                        c_comma as token = ',' and 1=ddlt_util.always_true(1003),
                        c_end_exp as token = ')' and 1=ddlt_util.always_true(1005),
                        c_end_list as token = ')' and 1=ddlt_util.always_true(1002),
                        c_end_obj_array as token = ')' and 1=ddlt_util.always_true(1009),
                        c_obj_comma as token = ',' and 1=ddlt_util.always_true(1010),
                        c_start_exp as token = '(' and 1=ddlt_util.always_true(1004),
                        c_start_list as token = '(' and 1=ddlt_util.always_true(1001),
                        c_start_obj_array as token = '(' and 1=ddlt_util.always_true(1008),
                        e_item as 1=ddlt_util.always_true(119),
                        e_tok as 1=ddlt_util.always_true(138),
                        l_item as 1=ddlt_util.always_true(123),
                        l_priv as 1=ddlt_util.always_true(131),
                        n_acls as token = 'acls',
                        n_columns as token = 'columns',
                        n_domain as token = 'domain',
                        n_for as token = 'for',
                        n_source_columns as token = 'source_columns',
                        n_table as token = 'table',
                        n_target_columns as token = 'target_columns',
                        n_where as token = 'where',
                        o_table as 1=ddlt_util.always_true(135),
                        w_application as token = 'application',
                        w_create as token = 'create',
                        w_protects as token = 'protects',
                        w_references as token = 'references',
                        x_object_name as 1=ddlt_util.always_true(113),
                        x_object_type as token = 'policy',
                        x_privilege_name as 1=ddlt_util.always_true(128),
                        x_type as token in ( 'rls', 'foreign', 'privilege' )

                ) a;
