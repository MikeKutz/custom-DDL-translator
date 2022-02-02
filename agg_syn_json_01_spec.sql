create or replace type agg_syn_json is object (
    agg_syn_pk   int,
    lv           int,
    work_state   number(1),
    is_sub       number(1),    -- p2s
    current_name varchar2(50), -- json key
    json_txt     clob,         -- buffer_json_object
    temp_string  clob,         -- buffer_string
    temp_array   clob,         -- buffer_json_array
    sub_json     ref agg_syn_json,
    constructor function agg_syn_json return self as result,
    member procedure new_ref_obj( self in out nocopy agg_syn_json, p_lvl in int ),
    member function iterate_step ( self in out nocopy agg_syn_json, t in tokens_t ) return int,
    member function self_iterator( self in out nocopy agg_syn_json, t in tokens_t ) return int,
    member function sub_iterator ( self in out nocopy agg_syn_json, t in tokens_t ) return int,
    member procedure save_self
);
