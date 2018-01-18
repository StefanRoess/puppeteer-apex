create or replace package body pup_json_string
as

  /* ================================================================== */
  /* == Template Replace Functions ==================================== */
  /* ================================================================== */
  function replace_base_url( pi_source_script in clob
                           , pi_base_url      in varchar2 )
    return clob
  as
  begin
    return replace(pi_source_script, '#BASE_URL#', pi_base_url);
  end replace_base_url;

  /* ================================================================== */
  function replace_login_yes_no( pi_source_script in clob
                               , pi_login_yes_no  in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#LOGIN_YES_NO#', pi_login_yes_no);
  end replace_login_yes_no;

  /* ================================================================== */
  function replace_username( pi_source_script  in clob
                            , pi_username       in varchar2 )
    return clob
  as
  begin
    return replace(pi_source_script, '#USERNAME#', pi_username);
  end replace_username;

  /* ================================================================== */
  function replace_password( pi_source_script  in clob
                            , pi_password       in varchar2 )
    return clob
  as
  begin
    return replace(pi_source_script, '#PASSWORD#', pi_password);
  end replace_password;

  /* ================================================================== */
  function replace_app_id( pi_source_script in clob
                         , pi_app_id        in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#APP_ID#', pi_app_id);
  end replace_app_id;

  /* ================================================================== */
  function replace_page_id( pi_source_script in clob
                          , pi_page_id       in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#PAGE_ID#', pi_page_id);
  end replace_page_id;

  /* ================================================================== */
  function replace_direct_page( pi_source_script in clob
                              , pi_direct_yes_no in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#DIRECT_YES_NO#', pi_direct_yes_no);
  end replace_direct_page;

  /* ================================================================== */
  function replace_modal_page( pi_source_script in clob
                             , pi_modal_yes_no  in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#MODAL_YES_NO#', pi_modal_yes_no);
  end replace_modal_page;

  /* ================================================================== */
  function replace_items( pi_source_script in clob
                        , pi_items         in clob )
    return clob
  as
  begin
    return replace(pi_source_script, '#PAGE_ITEMS#', pi_items);
  end replace_items;

  /* ================================================================== */
  function replace_item_types( pi_source_script in clob
                             , pi_items         in clob )
    return clob
  as
  begin
    return replace(pi_source_script, '#PAGE_ITEM_TYPES#', pi_items);
  end replace_item_types;

  /* ================================================================== */
  function replace_item_values( pi_source_script in clob
                              , pi_items         in clob )
    return clob
  as
  begin
    return replace(pi_source_script, '#PAGE_ITEM_VALUES#', pi_items);
  end replace_item_values;

  /* ================================================================== */
  function replace_screenshot( pi_source_script    in clob
                             , pi_screenshot       in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#SCREENSHOT#', pi_screenshot);
  end replace_screenshot;

  /* ================================================================== */
  function replace_pdf( pi_source_script in clob
                      , pi_pdf           in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#PDF#', pi_pdf);
  end replace_pdf;

  /* ================================================================== */
  function replace_viewport_height( pi_source_script         in clob
                                  , pi_viewport_height       in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#VIEWPORT_HEIGHT#', pi_viewport_height);
  end replace_viewport_height;

  /* ================================================================== */
  function replace_viewport_width( pi_source_script     in clob
                                 , pi_viewport_width    in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#VIEWPORT_WIDTH#', pi_viewport_width);
  end replace_viewport_width;

  /* ================================================================== */
  function replace_delay( pi_source_script in clob
                        , pi_delay         in number )
    return clob
  as
  begin
    return replace(pi_source_script, '#DELAY#', pi_delay);
  end replace_delay;

 /* ================================================================== */
  function replace_parameter( pi_source_script  in clob
                            , pi_parameter      in clob )
    return clob
  as
  begin
    return replace(pi_source_script, '#PARAMETER#', pi_parameter);
  end replace_parameter;

  /* ================================================================== */
  function replace_ig_tab_save_call( pi_source_script in clob
                                   , pi_save_script in varchar2 )
    return clob                  
  as
  begin                          
    return replace(pi_source_script, '#IG_TAB_SAVE_CALL#', pi_save_script);
  end replace_ig_tab_save_call;

  /* ================================================================== */
  function replace_ig_tab_update_call( pi_source_script in clob
                                     , pi_update_script in varchar2 )
    return clob
  as                             
  begin                          
    return replace(pi_source_script, '#IG_TAB_UPDATE_CALL#', pi_update_script);
  end replace_ig_tab_update_call;

  /* ================================================================== */
  function replace_ig_tab_delete_call( pi_source_script in clob
                                    , pi_delete_script in varchar2 )
    return clob                  
  as                             
  begin
    return replace(pi_source_script, '#IG_TAB_DELETE_CALL#', pi_delete_script);
  end replace_ig_tab_delete_call;

------------------
-- end of program
------------------
end pup_json_string;
