set serveroutput on;
set timing on;
declare
    p clob;
    s clob;
    tt tokens_nt;
    err_code int;
    
    a token_aggregator_obj := new token_aggregator_obj;
    sql_txt clob;
    
    test_no  int := 7;
begin
    for test# in 1 .. 10
    loop

    s := ddlt_ut.sample_ut( test# );
    p := ddlt_ut.sample_utp( test# );
    
    begin
        tt := ddlt_util.pattern_parser(  s
                                        ,p
                                        ,ddlt_util.mr_define_exp_hash()
                                        ,sql_txt );
--    exception
--        when others then null;
    end;
    
    delete from ddlt_matched_tokens_temp;
    insert into ddlt_matched_tokens_temp
    select * from table(tt);
    
    a := new token_aggregator_obj();
    for t in (select * from table(tt) order by rn)
    loop
        null;
        err_code := a.iterate_step( tokens_t(t.match#, t.match_class, t.rn, t.token));
    end loop;
    dbms_output.put_line( 'TEST # ' || to_char(test#,'99') );
    dbms_output.put_line( 'statement  ="' || s || '"' );
    dbms_output.put_line( 'pattern    ="' || p || '"' );
    dbms_output.put_line( 'JSON result=' || a.json_txt);
    dbms_output.put_line( '---------------------------' );




--    dbms_output.put_line( 'pat ="' || p || '"');
    
--    dbms_output.put_line( ' SQL = ' || sql_txt );
    end loop;

end;
/

