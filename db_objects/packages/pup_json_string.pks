create or replace package pup_json_string
as

  /* ================================================================== */
  /* == Template_JSON_String ========================================== */
  /* ================================================================== */
  c_json_string pup_constants.t_max_vc2 := regexp_replace(q'[
    % var pupTest = {
    %    "base_url": "#BASE_URL#,
    %    "login": { "needed": #LOGIN_YES_NO#, "usr": #USERNAME#, "pw": #PASSWORD# },
    %    "app_id": #APP_ID#,
    %    "pages": [{
    %       "page": #PAGE_ID#,
    %       "access" :
    %              {
    %                  "direct": #DIRECT_YES_NO#,
    %                  "modal": #MODAL_YES_NO#,
    %                  "over": "340",
    %                  "click": "selector here"
    %              },
    %       "test": [ "validation", "processing" ],
    %       "item": [ #PAGE_ITEMS#
    %       ],
    %       "type": [ #PAGE_ITEM_TYPES#
    %       ],
    %       "item_value": [ #PAGE_ITEM_VALUES#
    %       ]
    %     }],
    %     "screenshot": #SCREENSHOT#,
    %     "pdf": #PDF#,
    %     "viewport" : {"height": #VIEWPORT_HEIGHT#, "width": #VIEWPORT_WIDTH# },
    %     "delay": #DELAY#
    % }
    ]',
    '^\s+% ', null, 1, 0, 'm' );

  function replace_base_url( pi_source_script in clob
                           , pi_base_url      in varchar2 )
    return clob;

  function replace_login_yes_no( pi_source_script in clob
                               , pi_login_yes_no  in number )
    return clob;

  function replace_username( pi_source_script  in clob
                           , pi_username       in varchar2 )
    return clob;

  function replace_password( pi_source_script  in clob
                           , pi_password       in varchar2 )
    return clob;

  function replace_app_id( pi_source_script in clob
                         , pi_app_id        in number )
    return clob;

  function replace_page_id( pi_source_script in clob
                          , pi_page_id       in number )
    return clob;

  function replace_direct_page( pi_source_script in clob
                              , pi_direct_yes_no in number )
    return clob;

  function replace_modal_page( pi_source_script in clob
                             , pi_modal_yes_no  in number )
    return clob;

  function replace_items( pi_source_script in clob
                        , pi_items         in clob )
    return clob;

  function replace_item_types( pi_source_script in clob
                             , pi_items         in clob )
    return clob;

  function replace_item_values( pi_source_script in clob
                              , pi_items         in clob )
    return clob;

  function replace_screenshot( pi_source_script in clob
                             , pi_screenshot    in number )
    return clob;

  function replace_pdf( pi_source_script in clob
                      , pi_pdf           in number )
    return clob;

  function replace_viewport_height( pi_source_script   in clob
                                  , pi_viewport_height in number )
    return clob;

  function replace_viewport_width( pi_source_script   in clob
                                 , pi_viewport_width  in number )
    return clob;

  function replace_delay( pi_source_script in clob
                        , pi_delay         in number )
    return clob;

  function replace_ig_tab_save_call( pi_source_script in clob
                                   , pi_save_script   in varchar2 )
    return clob;

  function replace_ig_tab_update_call( pi_source_script in clob
                                     , pi_update_script in varchar2 )
    return clob;

  function replace_ig_tab_delete_call( pi_source_script in clob
                                     , pi_delete_script in varchar2 )
    return clob;

end pup_json_string;