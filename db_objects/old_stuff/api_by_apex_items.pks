create or replace package api_by_apex_items
as
  type t_item is record
  (
    item_name               varchar2(255),
    display_as_code         varchar2(255),
    item_data_type          varchar2(255),
    is_required             varchar2(255),
    item_default            varchar2(255),
    region_name             varchar2(255),
    page_id                 number,
    region_source_type_code varchar2(255)
  );
  type t_items is table of t_item;

  type t_region is record
  (
    region_name       varchar2(255),
    source_type_code  varchar2(255)
  );
  type t_regions is table of t_region;

  type t_ig_item is record
  (
    item_name                 varchar2(255), --rowid
    region_name               varchar2(255), 
    region_source_type_code   varchar2(255), --(NATIVE_IG) 
    edit_operations           varchar2(255), --(i:u:d) 
    is_editable               varchar2(255), -- (Yes)
    item_data_type            varchar2(255), --parameter data types
    source_expression         varchar2(255), 
    db_column                 varchar2(255) --if db column
  );
  type t_ig_items is table of t_ig_item;

  type t_tabform_item is record
  (
    item_name varchar2(255),
    display_as_code varchar2(255),
    region_name varchar2(255),
    source_type_code varchar2(255)
  );
  type t_tabform_items is table of t_tabform_item;

  c_save_proc_name constant varchar2(30) := 'SAVE';
  c_load_details_proc_name constant varchar2(30) := 'LOAD_DETAILS';
  c_delete_proc_name constant varchar2(30) := 'DELETE';
  c_load_list_proc_name constant varchar2(30) := 'LOAD_LIST';
  c_update_proc_name constant varchar2(30) := 'UPDATE_RECORD';



  function check_has_tab_ig_on_page
    (
      pi_app_id in number,
      pi_page_id in number
    )
  return number;

  function get_proc_all_calls_for_apex
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob;
 
  function get_page_api
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob;

end api_by_apex_items;