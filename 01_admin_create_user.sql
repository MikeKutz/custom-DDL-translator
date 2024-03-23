create user cSQL
    identified by Change0nInstall
-- no authentication
default tablespace USERS
temporary tablespace TEMP
quota 10M on USERS;

grant create procedure
    ,create synonym
    ,create public synonym
    ,create type
    ,create table      
    ,create sequence   
    ,create indextype  -- for indexing Tags
    ,create session
to cSQL;

grant execute any procedure,
      execute any type,
      select any table,
      select any sequence
on schema teJSON to cSQL;

grant execute any domain
on schema MKLibrary to cSQL;

grant create sql translation profile to cSQL;
