BEGIN
    dbms_sql_translator.create_profile( profile_name => 'RAS_SQL');

  DBMS_SQL_TRANSLATOR.SET_ATTRIBUTE(
    profile_name     =>  'RAS_SQL', 
    attribute_name   =>  DBMS_SQL_TRANSLATOR.ATTR_TRANSLATOR, 
    attribute_value  =>  'cSQL.ddlt_translator');

end;
/

-- BEGIN
--     dbms_sql_translator.DROP_PROFILE( profile_name => 'RAS_SQL');
-- end;
-- /
