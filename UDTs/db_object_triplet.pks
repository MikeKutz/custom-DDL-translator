create or replace
type db_object_triplet as object (
   first_name varchar2(128)
  ,middle_name varchar2(128)
  ,last_name   varchar2(128)  -- first part
  ,parts       int
  ,constructor function db_object_triplet return self as result
  ,constructor function db_object_triplet( self in out nocopy db_object_triplet, txt in varchar2 ) return self as result
  ,member procedure init(self in out nocopy db_object_triplet, txt in varchar2 )
);
/
