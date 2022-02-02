create table temp_syn of agg_syn_json
object identifier is system generated;

alter table temp_syn add
    constraint temp_syn_pk primary key ( agg_syn_pk );



select * from temp_syn;