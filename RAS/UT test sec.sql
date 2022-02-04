set serveroutput on;
declare
    s clob;
    p clob;
    
    tt tokens_nt;
    err_code int;
    
    a token_aggregator_obj := new token_aggregator_obj;
    sql_txt clob;
begin
    s := ddlt_ras_ut.sample_security_class( 1 );
    p := ddlt_ras.get_pattern( ddlt_ras.security_class );
    dbms_output.put_line(s);
    dbms_output.put_line(p);
    
    tt := ddlt_util.pattern_parser( s
                                    ,p
                                    ,ddlt_ras.get_define( ddlt_ras.security_class )
                                    ,sql_txt );

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
