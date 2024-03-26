create or replace
package body ddlt_errors
as
  type text_hash is table of varchar2(1000) index by error#;

  error_texts constant text_hash := text_hash(
    g_general_error      => 'Generic error occured in %1'
    ,g_missing_keyword   => 'Missing keyword. Try %1'
    ,g_bad_combination   => 'Option %1 and %2 are not supported simultanously'
    ,g_object_exists     => '%1 %2 exists'
    ,g_object_not_exists => '%1 %2 does not exists'
  );

  -- procedure "_replace"( text in out nocopy varchar2
  --                         ,p_1 in varchar2 default null
  --                         ,p_2 in varchar2 default null
  --                         ,p_3 in varchar2 default null
  --                         ,p_4 in varchar2 default null
  --                       )
  -- as
  -- begin
  --   text := replace( text, '%1', p_1 );
  --   text := replace( text, '%1', p_2 );
  --   text := replace( text, '%1', p_3 );
  --   text := replace( text, '%1', p_4 );
  -- end "_replace";    

  function get_error_text( error_code error#
                          ,p_1 in varchar2 default null
                          ,p_2 in varchar2 default null
                          ,p_3 in varchar2 default null
                          ,p_4 in varchar2 default null
                        ) return varchar2
  as
    ret_val  varchar2(1000);

    procedure "_replace"( p_1 in varchar2 default null
                          ,p_2 in varchar2 default null
                          ,p_3 in varchar2 default null
                          ,p_4 in varchar2 default null
                        )
    as
    begin
      ret_val := replace( ret_val, '%1', p_1 );
      ret_val := replace( ret_val, '%2', p_2 );
      ret_val := replace( ret_val, '%3', p_3 );
      ret_val := replace( ret_val, '%4', p_4 );
    end "_replace";    

  begin
    if error_texts.exists( error_code )
    then
      ret_val := error_texts( error_code );
      "_replace"( p_1, p_2, p_3, p_4 );
    else
      ret_val := 'Unknown DDLT code';
    end if;

    return ret_val;
  end;

end ddlt_errors;
/
