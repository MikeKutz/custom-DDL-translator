create or replace
package policy_generator
as
    json_text clob := 
q'[{
  "policy_name" : "hr_policy",
  "rules" :
  [
    {
      "type" : "domain",
      "domain_clause" : "department_id=60",
      "acls" :
      [
        "it_acl"
      ]
    },
    {
      "type" : "domain",
      "domain_clause" : "1=1",
      "acls" :
      [
        "auditor_acl",
        "hr_acl"
      ]
    },
    {
      "type" : "domain",
      "domain_clause" : "employee_id=xs_session('xs$session','user_name')",
      "acls" :
      [
        "emp_acl"
      ]
    },
    {
      "type" : "privilege",
      "privilege_name" : "view_salary",
      "column_names" :
      [
        "pii",
        "salary"
      ]
    },
    {
      "type" : "foreign",
      "target_table" : null,
      "source_columns" :
      [
        "empno",
        "deptno"
      ],
      "target_column" :
      [
        "employee_id",
        "department_id"
      ],
      "where_clause" : "private=1"
    }
  ]
}{
  "policy_name" : "hr_policy",
  "rules" :
  [
    {
      "type" : "domain",
      "domain_clause" : "department_id=60",
      "acls" :
      [
        "it_acl"
      ]
    },
    {
      "type" : "domain",
      "domain_clause" : "1=1",
      "acls" :
      [
        "auditor_acl",
        "hr_acl"
      ]
    },
    {
      "type" : "domain",
      "domain_clause" : "employee_id=xs_session('xs$session','user_name')",
      "acls" :
      [
        "emp_acl"
      ]
    },
    {
      "type" : "privilege",
      "privilege_name" : "view_salary",
      "column_names" :
      [
        "pii",
        "salary"
      ]
    },
    {
      "type" : "foreign",
      "target_table" : null,
      "source_columns" :
      [
        "empno",
        "deptno"
      ],
      "target_column" :
      [
        "employee_id",
        "department_id"
      ],
      "where_clause" : "private=1"
    }
  ]
}]';

    cursor all_domains(txt clob) is
        select *
        from json_table( txt, '$.rules[*]' --?( @.type=="domain"  )
        columns (
            mn  for ORDINALITY,
            rule_type varchar2(15) path '$.type',
            domain_clause varchar2(32767)  path '$.domain_clause',
            nested '$.acls[*]' columns (
                acl_# for ordinality,
                acl varchar2(15) path '$.string()'
            )
        ) )
        where rule_type = 'domain'
        order  by mn, acl_# desc;



    function get_text  return clob;
    
    function get_policy_name( txt in clob ) return varchar2;


end;
/

create or replace
package body policy_generator
as
    function get_text return clob
    as
    begin
        return json_text;
    end;
    
    function get_policy_name( txt in clob ) return varchar2
    as
        ret varchar2(50);
    begin
        select json_value( txt, '$.policy_name' )
            into ret
        from dual;
        
        return ret;
    end;
    
$if false $then
<%@ template( template_name=ras_policy ) %>
<%!
    txt clob := q'!${json}'!';
%>
/***
generated on: <%$= sys_timestamp %>;

policy = "<%= '' %>";
 
json: "<%= txt %>"

******************************/
declare
    lkjl
begin
<% for rec in policy_generator.all_domains( txt ) loop %>
    <%@ include( ras_policy.acl_entry ) %>
<% end loop; %>

<% for rec in policy_generator.all_fks( txt ) loop %>
    <%@ include( ras_policy.fk_entry ) %>
<% end loop; %>

<% for rec in policy_generator.all_privs( txt ) loop %>
    <%@ include( ras_policy.privilege_entry ) %>
<% end loop; %>

    xs_policy.create_policy( policy_name => '<%= policy_generator.get_policy_domain( txt ) %>'
        domains => doms, columns => cols );
end;
<%= '/' %>

--------------
$end

$if false $then
<%@ template( template_name=ras_policy.acl_entry ) %>
<% if rec.is_first = 1 then %>
    acl_list := empty_acl_list;
<% end if; %>
    acl_list.extend(1);
    acl_list( acl_list.last ) := '<%= rec.acl %>';
<% if rec.is_last = 1 then %>
    dom.extend(1);
    dom( dom.last ) := XS$DOMAIN_TYPE(
        domain => q'{<%= rec.domain_clause %>}',
        acls   => acl_list
        );
<% end if; %>
$end

$if false $then
<%@ template( template_name=ras_policy.privilege_entry ) %>
<% if rec.is_first = 1 then %>
    col_list := empty_col_list;
<% end if; %>
    col_list.extend(1);
    col_list( col_list.last ) := '<%= rec.protected_column %>';
<% if rec.is_last = 1 then %>
    col_set.extend(1);
    col_set( col_set.last ) := xs$column_priv(
            privilege_name => '<%= rec.privilege_name %>',
            column_list => col_list
        );
<% end if; %>
$end

$if false $then
<%@ template( template_name=ras_policy.fk_entry ) %>
<% if rec.is_first = 1 then %>
    column_map := empty_column_map;
<% end if; %>
    column_map.extend(1);
    column_map( column_map.last ) :=
 xs$column( source_column => '<%= rec.source_column %>',
            target_column => '<%= rec.target_column %>',
            type = q  );
<% if rec.is_last = 1 then %>
    cols.extend(1)
    cols(cols.last) := xs$col(
        target_schema => '<%= rec.target_schema %>',
        target_table  => '<%= rec.target_table %>',
        colum_list    => column_map,
        where_clause  => q'{<%= rec.where_clause %>}'
    );
<% end if; %>
-----------
$end
    
end;
/