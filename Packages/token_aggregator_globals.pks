create or replace
package token_aggregator_globals
as
    /** cross-object globals used by TOAKE_AGGREGATOR **/
    subtype state_t is number(1);
    work_on_self       constant state_t := 0;
    work_on_expression constant state_t := 1;
    work_on_array      constant state_t := 2;
    work_on_sub_object constant state_t := 3;
    work_on_sub_object_array constant state_t := 4;

    p2s_no    constant state_t := 0;
    p2s_yes   constant state_t := 1;

end;
/
