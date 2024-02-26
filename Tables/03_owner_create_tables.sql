create table SQL_Actions (
  action_name MKLibrary.object_name_d,
  constraint SQL_Actions_pk primary key (action_name)
);

insert into SQL_Actions ( action_name )
  select 'create' union all
  select 'drop' union all
  select 'alter' union all
  select 'insert' union all
  select 'update' union all
  select 'select' union all
  select 'delete';

commit;
  
  

create table code_groups (
  group_name  MKLibrary.object_name_d,
  group_desc  MKLibrary.short_desc_d,
  constraint code_groups primary key (group_name)
);

create table code_object (
  object_id   int generated always as identity,
  group_name  MKLibrary.object_name_d,
  object_name MKLibrary.object_name_d,
  object_desc MKLibrary.short_desc_d,
  domain MKLibrary.id_d( object_id ),
  constraint code_object_pk primary key (object_id),
  constraint code_object_fk1 foreign key (group_name) references code_groups(group_name) on delete cascade,
  constraint code_object_uq1 unique (group_name,object_name)
);

create table code_commands (
  command_id  MKLibrary.id_d generated always as identity,
  action_name MKLibrary.object_name_d,
  group_name  MKLibrary.object_name_d,
  object_name MKLibrary.object_name_d,
  matchrecognise_pattern CLOB,
--  matchrecognise_define  MKLibrary.Hash_t,
  string_match varchar2(300 char) as (action || ' ' || group || ' ' || object || ' %'),
  constraint code_commands_pk primary key (command_id),
  constraint code_commands_uq1 unique (action_name, group_name, object_name),
  constraint code_commands_fk1 foreign key (group_name, object_name) references code_object( croup_name, object_name)
);

