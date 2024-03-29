create or replace package ddlt_util
as
    /*
    * utility packagee for  preparing  and  parsing commands
    *
    *  REFACTOR IN PROGRESS
    *  - DONE - matchrecognize (mr_*) types/constants/code moved to parser_util (should be syntax_parser_util)
    *  - TODO - move of exceptions to DDLT_ERRORS (still need to redirect references)
    *  - TODO - move JSON manipulations to MKLibrary.json_util
    *  - TODO - move global variables to TOKEN_AGGREGATOR_GLOVALS
    *
    * @headcom
    */
    subtype ras_obj_name_t is varchar2(50);

    type ddl_info_t is record (  command_text   ras_obj_name_t
                                ,command_group  ras_obj_name_t
                                ,object_type    ras_obj_name_t );

    /* list of PATTERN objects needed for MATCH_RECONGIZE clause */
    type mr_keys is table of ras_obj_name_t;
    
    /* hash of PATTERN=>EXPRESION items
    *  needed to build DEFINE of MATCH_RECOGNIZE
    */
    type mr_define_exp_hash is table of clob index by ras_obj_name_t;
    type mr_pattern_hash is table of clob index by ras_obj_name_t;
    type mr_define_hash_hash is table of mr_define_exp_hash index by ras_obj_name_t;
    
    /* known standard MATCH_RECOGNIZE DEFINE components
            c_start_list       as token = '(' and 1=ddlt_util.always_true(101),
            c_end_list         as token = ')' and 1=ddlt_util.always_true(102),
            c_comma            as token = ',' and 1=ddlt_util.always_true(103),
            c_start_exp        as token = ',' and 1=ddlt_util.always_true(104),
            c_end_exp          as token = ',' and 1=ddlt_util.always_true(105),
            c_start_obj        as token = '(' and 1=ddlt_util.always_true(106),
            c_end_obj          as token = ')' and 1=ddlt_util.always_true(107)
            c_start_obj_array  as token = '(' and 1=ddlt_util.always_true(108),
            c_end_obj_array    as token = ')' and 1=ddlt_util.always_true(109),
            c_obj_comma        as token = ',' and 1=ddlt_util.always_true(110)

    */
    mr_standard_def mr_define_exp_hash := mr_define_exp_hash(
        'w_create'           => q'[token = 'create']',
        'w_alter'            => q'[token = 'alter']',
        'w_drop'             => q'[token = 'drop']',
        'c_start_list'       => q'[token = '(' and 1=ddlt_util.always_true(1001)]',
        'c_end_list'         => q'[token = ')' and 1=ddlt_util.always_true(1002)]',
        'c_comma'            => q'[token = ',' and 1=ddlt_util.always_true(1003)]',
        'c_start_exp'        => q'[token = '(' and 1=ddlt_util.always_true(1004)]',
        'c_end_exp'          => q'[token = ')' and 1=ddlt_util.always_true(1005)]',
        'c_start_obj'        => q'[token = '(' and 1=ddlt_util.always_true(1006)]',
        'c_end_obj'          => q'[token = ')' and 1=ddlt_util.always_true(1007)]',
        'c_start_obj_array'  => q'[token = '(' and 1=ddlt_util.always_true(1008)]',
        'c_end_obj_array'    => q'[token = ')' and 1=ddlt_util.always_true(1009)]',
        'c_obj_comma'        => q'[token = ',' and 1=ddlt_util.always_true(1010)]',
        'c_semi'             => q'[token = ';' and 1=ddlt_util.always_true(1011)]',
        'c_hash'             => q'[token = ';' and 1=ddlt_util.always_true(1012)]'
    );
    
    /* moved to DDLT_ERRORS */
    -- general_error exception;
    -- PRAGMA EXCEPTION_INIT (general_error, -20700);
    
    /* moved to TOKEN_AGGREGATOR_GLOBALS */
    /** used by SYN AGGREGATOR **/
    -- subtype state_t is number(1);
    -- work_on_self       constant state_t := 0;
    -- work_on_expression constant state_t := 1;
    -- work_on_array      constant state_t := 2;
    -- work_on_sub_object constant state_t := 3;
    -- work_on_sub_object_array constant state_t := 4;
    
    -- p2s_no    constant state_t := 0;
    -- p2s_yes   constant state_t := 1;
    
    
    /*
    * function removes comments  and double-spaces and chr(10)
    * it WILL interfere with quotes
    *
    * @param txt unclean command  line
    * @return cleeaneed command  line
    */
    function  normalize_code( txt in clob ) return clob;
    
    /*
    *  converts  a  CLEAN command line  into tokens to be proceessed
    *
    * XMLPath  = /cmd/token
    * 
    * @param txt CLEAN  command line
    * @return   parsed XML  tree of  tokens
    */
    function convert2tree( txt in clob ) return xmltype;
    
    function parse_xml_tokens( xml_tokens in xmltype) return tokens_nt pipelined;
    
    /*
    * overload for '1=1' pattern definition of MATCH_RECGONIZE
    */
    function always_true( n in int ) return int DETERMINISTIC;
    
    /* safely converts text (including NULLS) into json_object_t */
    function safe_clob2json_object( txt in clob ) return json_object_t;

    /* safely converts text (including NULLS) into json_array_t */
    function safe_clob2json_array(txt in clob ) return json_array_t;
    
    /**
    *   appends key:value to input JSON object text
    *
    * @param txt         Text representing a JSON object (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param key         Value of the "key" in key:value
    * @param string_txt  Value of the "value" in key:value
    */
    procedure append_key_string( txt in out nocopy clob, key in varchar2, string_txt in clob );

    /**
    *   appends key:JSON ARRAY to input JSON Object text
    *
    * @param txt         Text representing a JSON object (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param key         Value of the "key" in key:value
    * @param array_txt   Text representin JSON Array for the "value" in key:value
    */
    procedure append_key_array( txt in out nocopy clob, key in varchar2, array_txt in clob );

    /**
    *   appends key:JSON Object to input JSON Object text
    *
    * @param txt       Text representing a JSON object (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param key       Value of the "key" in key:value
    * @param obj_txt   Text representing JSON Object for the "value" in key:value
    */
    procedure append_key_object( txt in out nocopy clob, key in varchar2, object_txt in clob );

    /**
    *   appends a string to the input JSON Array text
    *
    * @param txt         Text representing a JSON Array (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param string_txt  String to be appended to the JSON Array text
    */
    procedure append_array_string( txt in out nocopy clob, string_txt in varchar2 );

    /**
    *   appends a text of a JSON Object to the input JSON Array text
    *
    * @param txt         Text representing a JSON Array (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param object_txt  Text representing a JSON object that is to be appended to the JSON Array text
    */
    procedure append_array_object( txt in out nocopy clob, object_txt in clob);

    /**
    *   appends a string to the input JSON Array text
    *
    * @param txt         Text representing a JSON Array (NULLS allowed); THIS IS MODIFIED IN-PLACE
    * @param array_txt   Text representing a JSON Array that is to be appended to the JSON Array text
    */
    procedure  append_array_array( txt in out nocopy clob, array_text in clob);
    
    /* convert PATTERN into list of unique keys */
    -- function pattern_to_definition_keys( txt in clob ) return mr_keys;

    /* builds the DEFINE clause of a MATCH_RECOGINZE statement
    *
    * 
    * @param pattern_txt        actual PATTERN clause
    * @param definition_clause  additional DEFINE clause elements
    * @return complete DEFINITION clause that meets the needs of the give PATTERN clause
    */
    function build_define_clause( pattern_txt in clob, definition_hash in mr_define_exp_hash) return clob;
    
    /* converts a hash of define into actual DEFINE clause
    *  no alterations are done 
    *
    *  @param def_hash hash of values to be converted
    *  @return text representing DEFINE clause of MATCH_RECOGNIZE
    */
    function define_hash_to_clause( def_hash in mr_define_exp_hash ) return clob;
    
    /* extracts the keys of a hash into an array
    *  The array is used for MULTISET operations
    *
    *  @param def_hash the hash value who's keys needed to be extracted
    *  @return array of key values
    */
    function keys_to_array( def_hash in mr_define_exp_hash ) return mr_keys;
    
    /** future
        SQL_TABLE_MACRO( table_part, pattern_txt, definition_txt)
        dynamic wrapper
    **/
    /*      NOT COMPLETED
    *  @param p_tab           NOT NULL table expression to run MATCH_RECOGNICE on
    *  @param pattern_txt     PATTERN clause (without outer parenthesises)
    *  @param definition_txt  DEFINITION clause
    *  @return  all SQL statements are equivelent to TOKENS_NT PIPELINE
    */
--    function mr(p_tab dbms_tf.table_t, pattern_txt in clob, deinition_txt in clob)
--          return varchar2 sql_macro(table);
    

    -- function build_dyna_mr(pattern_txt in clob, definition_txt in clob) return clob;

    /*
        function pattern_parser( pattern_txt in clob, custom_dev in mr_define_exp_hash ) return tokens_nt
        calls DBMS_SQL
        may not be fit for PIPELINED function
    */
    -- function pattern_parser( statement_txt in clob, pattern_txt in clob, custom_dev in mr_define_exp_hash, sql_txt out clob, run_sql boolean default true ) return tokens_nt;

  function prepare_name_for_dd( txt in varchar2 ) return varchar2
    deterministic;

  /* these stay - maybe */
  procedure assert_schema_exists( uname in varchar2);
  procedure assert_schema_not_exists( uname in varchar2 );

  procedure assert_object_exists( uname in varchar2, oname in varchar2);
  procedure assert_object_not_exists( uname in varchar2, oname in varchar2);
  
  procedure assert_package_exists( uname in varchar2);
  procedure assert_package_not_exists( uname in varchar2);

  procedure assert_type_exists( uname in varchar2);
  procedure assert_type_not_exists( uname in varchar2);

  /* checks for actual table
     TODO - check for any selectable object (table/mv/v/objec table)
  */
  procedure assert_btable_exists( uname in varchar2);
  procedure assert_btable_not_exists( uname in varchar2);

  procedure assert_view_exists( uname in varchar2);
  procedure assert_view_not_exists( uname in varchar2);

  procedure assert_domain_exists( uname in varchar2);
  procedure assert_domain_not_exists( uname in varchar2);

  -- selectable table
  -- column
  -- synonym
  -- function/procedure
  -- check constraint
  -- UQ (includes PK)

  procedure assert_index_exists( uname in varchar2);
  procedure assert_index_not_exists( uname in varchar2);

  procedure assert_sequence_exists( uname in varchar2);
  procedure assert_sequence_not_exists( uname in varchar2);


end;
/
