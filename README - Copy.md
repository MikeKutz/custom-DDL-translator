# custom DDL translator
 Frame work for creating parsers for custom DDL statements.
 
 ## format
 
 Supported DDL statements are currently in this format:
 
 `(create|alter|drop) *command_group* *object_type*`
 
 # Real Application Security (RAS) objects
  
 Supported `CREATE` objects
 
 - Security class
 - ACL
 - Policy
 
 ## Security Class
 
 ### CREATE
 
 ## Syntax
 
 ```
 create application security class *security_class_name*
    under ( *security_class_list* )
  [ define privileges ( *privilege_list* ) ]
```
 
 - The segment `*security_class_list*` is a comma separated list of existing Security Classes
 - The segment `*privilege_list*` is a comma separated list of new (for this Security Class) privileges.
 
 ### example
 
 This statement
 
 ```sql
 create application security class hr_sec_class
    under ( sys.dml, sys.nsstuff ) define privileges ( view_salary, PPI )
 ```
 
 Builds this JSON
 
 ```
 json
 ```
 
 Generates this code
 
 ```sql
 tbd
 ```
 
 
 ## ACL
 
 ### CREATE
  
```
 create application acl *acl_name*
    for security class *security_class*
    aces ( *ace_entries* )
```

Single ACE Entry

```
principal *principal_name* privileges ( *privilege_list* )
```

 - `*acl_name* is a valid RAS object name
 - `*security_class*` is an existing security class ( `DBA_XS_SECURITY_CLASSES` )
 - `ace_entries` is a comma separated list of an ACE Entry
 - `*privilege_list*` is a comma separated list of privileges known to the Security Class
 
 
 ### Example (acl test# 1)
 
 This statement
 
 ```sql
 create application acl hr_acl for security class hrpriv aces (
    principal hr_representive aces ( insert,update,select,delete,view_salary ),
    principal auditor aces ( select, view_salary )
 )
```

Builds this JSON

```
json
```

generates this code:

```sql
declare
    aces XS$ACE_LIST := new XS$ACE_LIST();
    priv XS$LIST;
    empty_priv XS$LIST := new XS$LIST();
begin

    priv := empty_priv;
    priv_list.extend(1); priv( priv.last ) := 'select';
    priv_list.extend(1); priv( priv.last ) := 'view_salary';

    ace.extend(1);
    ace( ace.last ) :=  XS$ACE_TYPE( principal => 'auditor',
                                     privilege => priv
               );
---------------------------------------------------------------

    priv := empty_priv;
    priv_list.extend(1); priv( priv.last ) := 'delete';
    priv_list.extend(1); priv( priv.last ) := 'insert';
    priv_list.extend(1); priv( priv.last ) := 'select';
    priv_list.extend(1); priv( priv.last ) := 'update';
    priv_list.extend(1); priv( priv.last ) := 'view_salary';

    ace.extend(1);
    ace( ace.last ) :=  XS$ACE_TYPE( principal => 'hr_representive',
                                     privilege => priv
               );
---------------------------------------------------------------

    xs_acl.create_acl( aces => aces,
                acl_name => 'hr_acl',
                sec      =>  'hrpriv'
            );
end;
/
```

## Policy

### CREATE

Main Statement

`create application policy *policy_name* for ( *csv_permissions* )`

CSV Permissions

```
*row_level_security* | *column_privilege_clause* | *foreign_key_refernce_clause*
```

Row Level Security

```
rls domain ( *realm_clause* ) acls ( *acl_list* ) [static|dynamic]
```

Column Privilege Clause

```
privilege *privilege_name* protects columns ( *column_list* )
```

Foreign Key Reference Clause
```
foreign source_columns ( *source_column_list* ) references table *target_table_name* target_columns ( *target_column_list* )
    [ where ( *where_clause* ) ]
```

## Example

This code (policy test# 5)

```sql
create application policy hr_policy for (
    rls domain ( department_id = 60 ) acls( it_acl ),
    rls domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    rls domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    foreign source_columns ( empno, deptno ) references table hr.employees target_columns ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns ( salary , ppi )
)
```

Builds this JSON
```
json
```

generates this code

```sql
-- TBD
```