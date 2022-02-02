create or replace
package ddlt_ut
as
    function sample_ut( n int default 1 ) return clob;
    function sample_utp( n int default 1 ) return clob;
    function generate_json( test# int default 1 ) return clob;
end;
/
