create or replace package ddlt_ras_ut
as
    function sample_security_class( n int default 1 ) return clob;
    function sample_acl( n int default 1 ) return clob;
    function sample_policy( n int default 1 ) return clob;

    
    function generate_code( n int default 1, ras_obj in varchar2 ) return clob;
    function generate_json( n int default 1, ras_obj in varchar2 ) return clob;

end;
/
