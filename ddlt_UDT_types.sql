create type tokens_t is object ( match# int, match_class varchar2(50), rn int, token varchar2(50) );
/

create type tokens_nt is table of tokens_t;
/

create global temporary table ddlt_tokens_temp of tokens_t;
create global temporary table ddlt_matched_tokens_temp of tokens_t;

