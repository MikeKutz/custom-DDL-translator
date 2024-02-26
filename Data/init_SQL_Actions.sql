insert into SQL_Actions ( action_name )
  select 'create' union all
  select 'drop' union all
  select 'alter' union all
  select 'insert' union all
  select 'update' union all
  select 'select' union all
  select 'delete';

commit;
