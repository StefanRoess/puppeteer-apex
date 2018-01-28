create or replace package pup_utils
as
  --------------------
  -- type declaration
  --------------------

  -------------------------
  -- function declaration
  -------------------------
  function get_version
    return varchar2;

  function get_linked_pages(
    pi_app_id      in number,
    pi_page_id     in number,
    pi_region_name in varchar2 default null
  )
    return varchar2;  

end pup_utils;