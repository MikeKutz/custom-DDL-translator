create or REPLACE
package ddlt_errors
  authid current_user
as
  /*  Common error codes for DDLT Custom Syntax Parser

    List of errors an P_x values in `get_error_text`:

    error name | P_1 | P_2 | P_3 | P_4
    -----------+-----+-----+-----+-----
     general_error  | name/object error occured | | |
     missing_keyword | keyword that is expected | | |
     bad_combination | name of option1 | name of Option 2 | |
     object_exists   | object_type | object_name | | 
     object_not_exists | object_type | object_name | | 

    example usage:

     ```sql
     exception
      when cSQL.ddlt_error.general_error then
        raise_application_error(
           cSQL.ddlt_error.g_general_error
          ,cSQL.ddlt_error.get_error_text( cSQL.ddlt_error.general_error
                                           ,p1, p2, p3, p4
                                          )
        );
    end;
    ```

  */

  subtype error# is PLS_INTEGER;

  g_general_error      constant error# := -20700;
  g_missing_keyword    constant error# := -20701;
  g_bad_combination    constant error# := -20702;
  g_object_exists      constant error# := -20703;
  g_object_not_exists  constant error# := -20704;

  general_error        exception; pragma exception_init( general_error,     g_general_error );
  missing_keyword      exception; pragma exception_init( missing_keyword,   g_missing_keyword );
  bad_combination      exception; pragma exception_init( bad_combination,   g_bad_combination );
  object_exists        exception; pragma exception_init( object_exists,     g_object_exists );
  object_not_exists    exception; pragma exception_init( object_not_exists, g_object_not_exists );

  function get_error_text( error_code error#
                          ,p_1 in varchar2 default null
                          ,p_2 in varchar2 default null
                          ,p_3 in varchar2 default null
                          ,p_4 in varchar2 default null
                        ) return varchar2;

end ddlt_errors;
/

