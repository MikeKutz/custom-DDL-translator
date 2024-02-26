create table syntax_lists  of syntax_parser_t;

  
alter table syntax_lists
  modify (syntax_action  domain MKLibrary.object_name_d,
          syntax_group   domain MKLibrary.object_name_d,
          syntax_subtype domain MKLibrary.object_name_d);

alter table syntax_lists
  add constraint syntax_lists_pk primary key (syntax_action, syntax_group, syntax_subtype);
alter table syntax_lists
  add constraint syntax_lists_fk1 foreign key (syntax_action) references sql_actions(action_name);
alter table syntax_lists
  add constraint syntax_lists_fk2 foreign key (syntax_group) references syntax_groups(group_name) on delete cascade;
