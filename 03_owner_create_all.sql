set define off;
-- run as owner
@ddlt_UDT_types.sql
@ddlt_util.pks
@ddlt_util.pkb

-- workaround for "?" code === recompile
alter package ddlt_util compile body;

-- DDLT_TOKEN2JSON
@token_aggregator_obj.pks
@token_aggregators.sql
@token_aggregator_obj.pkb



-- RAS packages
-- TBD

-- ut packages -- currently SQL file contains both
@test/ddlt_ut.pks
@test/ddlt_ut.pkb
