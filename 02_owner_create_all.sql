set define off;
-- run as owner
-- UDT specs
@@./UDTs/tokens_t.sql
@@./UDTs/tokens_nt.sql
@@./UDTs/token_aggregator_obj.pks
@@./UDTs/snippet_list.sql
@@./UDTs/syntax_parser_t.pks
@@./UDTs/db_object_triplet.pks
@@./UDTs/db_object_triplet.pkb -- needed to compile ddlt_util.pkb

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
@@./Packages/token_aggregator_globals.pks

-- workaround for "?" code === recompile
alter package ddlt_util compile body;

@@./Packages/parser_util.pks
@@./Packages/parser_util.pkb
@@./Packages/ddlt_errors.pks
@@./Packages/ddlt_errors.pkb
@@./Packages/ddlt_macros.pks
@@./Packages/ddlt_macros.pkb
@@./Packages/ddlt_util.pkb -- requires working ddlt_macros, db_object_triplet


-- UDT Bodies
@@./UDTs/token_aggregator_obj.pkb
@@./UDTs/syntax_parser_t.pkb

@@./Packages/ddlt_translator.pks
@@./Packages/ddlt_translator.pkb


-- UT packages -- currently SQL file contains both
@@./test/ddlt_ut.pks
@@./test/ddlt_ut.pkb
