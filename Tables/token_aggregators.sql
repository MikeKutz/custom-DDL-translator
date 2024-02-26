create table token_aggregators of token_aggregator_obj
object identifier is system generated;

alter table token_aggregators add
    constraint token_aggregators_pk primary key ( aggregator_pk );
    
comment on table token_aggregators is 'Table for REF cursor usage of sub-objects';

create sequence token_aggregator_seq;

