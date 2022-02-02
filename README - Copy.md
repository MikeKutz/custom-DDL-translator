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
 
 `create application security class *security_class_name* under ( *csv_security_class* )`
 
 The segment `*csv_security_class*` is a comma separated list of existing security classes;
 
 ### example
 
 ```sql
 create application security class hr_sec_class under ( sys.dml, sys.nsstuff )
 ```
 
 generates this code
 
 ```sql
 tbd
 ```
 
 
 ## ACL
 
 ### CREATE
 `create application acl *acl_name* aces ( *ace_entries* )`
 
 ACE entries are a comma separated list of ACE Entry.
 
 ### ACE Entry
 `*principal* => ( *csv_privilege* )
 
 ### Example
 
 ```sql
 create application acl hr_acl for security class hrpriv aces (
    hr_representive => ( insert,update,select,delete,view_salary ),
    auditor => ( select, view_salary ) ,
    assasin => ( poison, mdk, select, delete )
 )
```

generates this code:

```sql
declare
    aces XS$ACE_LIST := new XS$ACE_LIST();
    priv XS$LIST;
    empty_priv XS$LIST := new XS$LIST();
begin
    --  ace count = 2

    priv := empty_priv;
    priv_list.extend(1); priv( priv.last ) := 'delete';
    priv_list.extend(1); priv( priv.last ) := 'mdk';
    priv_list.extend(1); priv( priv.last ) := 'poison';
    priv_list.extend(1); priv( priv.last ) := 'select';

    ace.extend(1);
    ace( ace.last ) :=  XS$ACE_TYPE( principal => 'assasin',
                                     privilege => priv
               );
---------------------------------------------------------------

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

`create application policy *policy_name* for ( *csv_permissions* )`

### csv_permissions

comma seperate list of one of the following

- domain_definition
- foreign_key_definition
- privilege_definition

### domain_definition

This for defining a basic RLS rule withing RAS.

`domain ( *domain_clause* ) acls ( *csv_acls* ) [static|dynamic]`

- *domain_clause* is and SQL boolean expresion
- *csv_acls* is a comma separated list of ACL names (not quoted)
- static/dynamic clause is optional : `dynamic` is default

### foreign_key_definition

Used for MASTER-DETAIL policy enforcement.

`foreign_key ( *source_columns* ) references *target_schema_table* ( *target_columns* ) [ where ( *where_clause ) ]`

- *source_columns* - although RAS supports *expressions*, this generator does not at this time
- `where` clause is optional

### privilage

Assigns which columns are protected by which *privilege*. ( *privilege* is defined by the *security class*)

`privilege *privilege_name* protects columns ( *csv_colums* )`

### Example

```sql
create application policy hr_policy for (
    domain ( department_id = 60 ) acls( it_acl ),
    domain ( 1 = 1 ) acls ( hr_acl, auditor_acl ),
    domain ( employee_id = xs_session('xs$session','user_name') ) acls ( emp_acl ),
    foreign key ( empno, deptno ) references hr.employees ( employee_id, department_id ) where ( private = 1 ) ,
    privilage view_salary protects columns ( salary , ppi )
)
```

generates this code

```sql
-- TBD
```