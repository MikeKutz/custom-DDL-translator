create or replace
type token_aggregator_obj is object (
    -- WAS agg_syn_json
    aggregator_pk   int,
    lvl           int,
    work_state   number(1),
    is_sub       number(1),    -- p2s
    current_name varchar2(50), -- json key
    json_txt     clob,         -- buffer_json_object
    temp_string  clob,         -- buffer_string
    temp_array   clob,         -- buffer_json_array
    sub_json     ref token_aggregator_obj,
    constructor function token_aggregator_obj return self as result,
    member procedure new_ref_obj( self in out nocopy token_aggregator_obj, p_lvl in int ),
    member function iterate_step ( self in out nocopy token_aggregator_obj, t in tokens_t ) return int,
    member function self_iterator( self in out nocopy token_aggregator_obj, t in tokens_t ) return int,
    member function sub_iterator ( self in out nocopy token_aggregator_obj, t in tokens_t ) return int,
    member procedure save_self
);
