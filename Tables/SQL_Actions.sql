create table if not exists SQL_Actions (
  action_name MKLibrary.object_name_d,
  constraint SQL_Actions_pk primary key (action_name)
);

comment on table SQL_Actions is 'enum of grant/alter/drop etc.';
