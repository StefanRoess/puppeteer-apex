
create or replace package pup_dyn_regions
as
  /******************************************************************************
     NAME:       pup_dyn_regions
     PURPOSE:
     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        28.01.2018  Stefan Roess     1. Created this package.
  ******************************************************************************/
  procedure create_region(
     p_app_id       in number
    ,p_page_id      in number
    ,p_region_name  in varchar2 default null
  );

end;