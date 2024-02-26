set define off;
-- run as owner
-- UDT specs
@@./UDTs/tokens_t.sql
@@./UDTs/tokens_nt.sql
@@./UDTs/token_aggregator_obj.tks
@@./UDTs/syntax_parser_t.pks

-- Tables
@@./Tables/SQL_Actions.sql
@@./Tables/syntax_groups.sql
@@./Tables/gtt_tokens.sql
@@./Tables/token_aggregators.sql
@@./Tables/syntax_lists.sql

-- Sequences
-- @@./Sequences/token_aggregator_seq.sql

-- packages
@@./Packages/ddlt_util.pks
@@./Packages/ddlt_util.pkb

-- workaround for "?" code === recompile
alter package ddlt_util compile body;

@@./Packages/parser_util.pks.sql
@@./Packages/parser_util.pkb.sql


-- UDT Bodies
@@./UDTs/token_aggregator_obj.tkb
@@./UDTs/syntax_parser_t.pkb


-- UT packages -- currently SQL file contains both
@@./test/ddlt_ut.pks
@@./test/ddlt_ut.pkb
