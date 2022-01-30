create or replace
package body ddlt_ras_json2code
as
   function generate_code( json_txt clob, cmd varchar2, obj varchar2 )
        return clob
    as
    begin
        return null;
    end;
    
    function generate_security_class_create( txt clob ) return clob
    as
    begin
        null;
    end;
    
    function generate_acl_create( txt clob ) return clob
    as
    begin
        null;
    end;

    function generate_policy_create( txt clob ) return clob
    as
    begin
        null;
    end;
    

    
$if false $then
<%@ template( name=ddlt.main ) %>
<%!
    txt clob := q'|${json}|';
%>
/*
<%= txt %>
*/
<%@ include( ${generator} ) %>
$end

$if false $then
<%@ template( name=ddlt.acl.create ) %>
declare
    xx
begin

end;
$end

end;
/