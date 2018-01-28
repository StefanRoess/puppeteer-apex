create or replace package body pup_utils
as
   /******************************************************************************
      NAME:       pup_utils
      PURPOSE:    usefull procs and funcs for puppeteer

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        22.01.2018  Stefan Roess     1. Created this package.
   ******************************************************************************/

   ---------------------------------------------------------------------------------------
   --               Declare private types, cursor, exception                            --
   ---------------------------------------------------------------------------------------

   f_thispack  constant pup_constants.t_medium_vc2 := $$plsql_unit;
   f_version   constant pup_constants.t_small_vc2 := '01.00';

   ---------------------------------------------------------------------------------------
   --               Declare public callable subprograms                                 --
   ---------------------------------------------------------------------------------------

  function get_version
     return varchar2
  ----------------------------------------------------------------------------------------
  -- Returns version of this package
  --
  -- History:
  --  18.01.2018 V1.0   Stefan Roess
  ----------------------------------------------------------------------------------------
  is
  begin
     return f_version;
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  -----------------------------------------------------------
  -- call example:
  -- select pup_utils.get_linked_pages(136, 1, 'Dashboard') from dual;
  -----------------------------------------------------------
  function get_linked_pages(
    pi_app_id      in number,
    pi_page_id     in number,
    pi_region_name in varchar2 default null
  )
    return varchar2
  as
    l_return      varchar2(300);
    l_ref_page_id number := 0;
    l_cnt         number;
    i             number := 0;

  begin
    begin
      select regexp_count(region_source,'f?p=')
        into l_cnt
        from apex_application_page_regions a
        where 1=1
        and application_id  = pi_app_id
        and page_id         = pi_page_id
        and region_name     = coalesce(pi_region_name, region_name)
        and regexp_count(region_source,'f?p=') > 0;
    exception
      when too_many_rows then
        dbms_output.put_line('On Page '||pi_page_id||' is more than one region_source that references other pages.') ;
        dbms_output.put_line('Please enter the region_name as the third argument, like:');
        dbms_output.put_line('execute pup_utils.get_linked_pages(app_id, page_id, region_name)');
    end;

    for l_i in 1 .. l_cnt
    loop
      select to_number(
                substr( sub,instr(sub,':',1,2)+1
                      , instr(sub,':',1,3)-instr(sub,':',1,2)-1)
             ) ref_page_id
        into l_ref_page_id
        from (
                select regexp_count(region_source,'f?p=') anzahl
                      , substr(replace(lower(a.region_source), '&app_id.', '''||:app_id||''')
                       , instr(replace(lower(a.region_source), '&app_id.', '''||:app_id||''')
                             , '''f?p='''
                             , 1
                             , l_i
                        )
                      ) sub
                  from apex_application_page_regions a
                  where 1=1
                  and application_id  = pi_app_id
                  and page_id         = pi_page_id
                  and region_name     = coalesce(pi_region_name, region_name)
                  and regexp_count(region_source,'f?p=') > 0
              );      

      l_return := ltrim(l_return||':'||to_char(l_ref_page_id), ':');
     
    end loop;    
    
    return l_return;

  end;
  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */


------------------
-- end of program
------------------
end pup_utils;