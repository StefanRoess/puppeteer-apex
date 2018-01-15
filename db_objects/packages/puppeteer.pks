create or replace package puppeteer
as
  c_save_proc_name          constant varchar2(30) := 'SAVE';
  c_load_details_proc_name  constant varchar2(30) := 'LOAD_DETAILS';
  c_delete_proc_name        constant varchar2(30) := 'DELETE';
  c_load_list_proc_name     constant varchar2(30) := 'LOAD_LIST';
  c_update_proc_name        constant varchar2(30) := 'UPDATE_RECORD';

  type t_region is record
  (
    region_name       varchar2(255),
    source_type_code  varchar2(255)
  );
  type t_regions is table of t_region;
  
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
    item_name                 varchar2(255),
    display_as_code           varchar2(255),
    region_name               varchar2(255),
    source_type_code          varchar2(255)
  );
  type t_tabform_items is table of t_tabform_item;

  function get_json_code (
      pi_base_url                in varchar2 default null,
      pi_login_yes_no            in number,
      pi_username                in varchar2 default null,
      pi_password                in varchar2 default null,
      pi_app_id                  in number,
      pi_page_id                 in number,
      pi_direct_yes_no           in number,
      pi_modal_yes_no            in number,
      pi_region_name             in varchar2 default null,
      pi_screenshot              in number,
      pi_pdf                     in number,
      pi_viewport_height         in number,
      pi_viewport_width          in number,
      pi_delay                   in number,
      pi_tab_ig_prefix_proc_name in varchar2 default null --for the future to set it from outside
  )
    return clob;

  function check_has_tab_ig_on_page(
      pi_app_id   in number,
      pi_page_id  in number
  )
    return number;  

  function modal_page_yes_no(
      pi_app_id   in number,
      pi_page_id  in number
  )
    return number;  


end puppeteer;