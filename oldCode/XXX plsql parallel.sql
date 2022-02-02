/* init_with_data
random name(s) ( from a sequence
    ,self.temp_input_table_name
    ,self.temp_output_table_name)
build table
copy new data to table
chunk on id
*/

/* actual code
replace &table. with actual table name
set as CHUNK SQL
*/

/* finalize code
do whatever (replace %table. names as appropriate)
copy data to internal variable
return that variable
*/

/*
input_schema
input_type
input_bind_name

output_schema
output_type
output_bind_name

".input_element_type"
".output_element_type"
".input_table_name" -- bind name is hard coded to &input.
".output_table_name" -- bind name is hard coded to &output.

parallel_level
chunck_sql
chunk_column (NULL == chunk by rowid)
finalize_sql

constructor( 'input.type', 'output.type', DATA in anytype ); -- creates ".xxx_table_name' also
set_chunk_sql (parses code)
set_finalize_sql (parses code)
set_chunk_by_number_col_name
run
retrieve data
*/
-- actual CHUNK_SQL statement
declare
    input_value  "#input_element_data_type#"  := new "#input_element_data_type#"();

    output_value "#output_element_data_type#" := new "#output_element_data_type#"();
    empty_output "#output_element_data_type#" := new "#output_element_data_type#"();
    
    cursor "&c." return ".input_element_type" is
        select * from "&input.";
begin
    for input_value in "&c."
    loop
        output_value := empty_output;
        
        <<place_per_chunk_SQL_here>>
    
        insert into "&output." values ret_val;
    end loop;
end;
/

-- retrieve data code
declare
    output_value "#output_NT_data_type#" := new "#output_NT_data_type#"();
begin
    <<if_finalize_SQL_is_null>>
    select value(a)
        bulk collect into output_value
    from "&output." a;
    
    :return := output_value;
end;
