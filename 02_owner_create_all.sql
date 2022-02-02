-- run as owner
@ddlt_UDT_types.sql
@ddlt_util.pks
@ddlt_util.pkb

-- fix for "?" code
alter package ddlt_util compile body;

-- DDLT_TOKEN2JSON
@agg_syn_json_01_spec.sql
@agg_syn_json_02_temp_table.sql
@agg_syn_json_03_body.sql



-- RAS packages
-- TBD

-- ut packages -- currently SQL file contains both
@test/ddlt_ut.pks
@test/ddlt_ut.pkb