create or replace package body puppeteer
as
  subtype t_max_vc2 is   varchar2(32767);
  c_cr          constant varchar2(10) := utl_tcp.crlf;
  c_space       constant varchar2(10) := ' ';
  c_space_space constant varchar2(10) := '  ';
  c_items       constant varchar2(10) := 'ITEMS';
  c_item_types  constant varchar2(20) := 'ITEM_TYPES';

 /* ================================================================== */
 /* == Templates ===================================================== */
 /* ================================================================== */
c_json_string constant t_max_vc2 := regexp_replace(q'[
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
  %       ]   
  %     }],
  %     "screenshot": #SCREENSHOT#,
  %     "pdf": #PDF#,
  %     "viewport" : {"height": #VIEWPORT_HEIGHT#, "width": #VIEWPORT_WIDTH# },
  %     "delay": #DELAY#
  % }
  ]',
  '^\s+% ', null, 1, 0, 'm' );


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


  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  -- $if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  -- $then
  --   function get_ig_apex_call_script(
  --       pi_app_id               in number,
  --       pi_page_id              in number,
  --       pi_load_save_or_delete  in varchar2,
  --       pi_procedure_name       in varchar2,
  --       pi_region_name          in varchar2 default null
  --     )
  --   return clob
  --   as
  --     l_ig_items                    t_ig_items := t_ig_items();
  --     l_apex_call_parameter_script  clob;
  --     l_return                      clob;
  --   begin

  --     l_ig_items := get_ig_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);
  --     -- l_ig_items := swap_pk_column_on_top(pi_ig_items =>l_ig_items);

  --     -- l_apex_call_parameter_script := get_apex_items(pi_ig_items            => l_ig_items
  --     --                                                              , pi_load_save_or_delete => pi_load_save_or_delete);

  --     l_return := replace_procedure_name(pi_source_script => l_return, pi_procedure_name => pi_procedure_name);
  --     l_return := replace_func_proc(pi_source_script => l_return, pi_func_proc => l_apex_call_parameter_script);

  --     return l_return;
  --   end get_ig_apex_call_script;
  -- $end

  /* ================================================================== */
  /* == get_page_items ================================================ */
  /* ================================================================== */
  function get_page_items(
      pi_app_id       in number,
      pi_page_id      in number,
      pi_region_name  in varchar2 default null
  )
    return t_items
  as
    l_return t_items;
  begin
    select aapi.item_name,
           aapi.display_as_code,
           case 
            when upper(aapi.display_as) = 'NUMBER FIELD' then 'NUMBER'
            when upper(aapi.item_data_type) = 'VARCHAR' then 'VARCHAR2'
              else upper(aapi.item_data_type)
           end item_data_type,
           aapi.is_required, -- Yes, No,
           aapi.item_default,
           aapr.region_name,
           aapr.page_id,
           aapr.source_type_code
    bulk collect into l_return
    from APEX_APPLICATION_PAGE_REGIONS aapr
    join APEX_APPLICATION_PAGE_ITEMS aapi
      on aapr.region_id       = aapi.region_id
    where aapr.application_id = pi_app_id
      and aapr.page_id        = pi_page_id
      and aapr.region_name    = coalesce(pi_region_name,aapr.region_name)
      and not exists (select 1 
                        from apex_application_page_items a 
                        where 1=1
                        and a.item_name = aapi.item_name
                        and a.display_as_code in ('NATIVE_HIDDEN', 'NATIVE_DISPLAY_ONLY'))
    order by aapi.display_sequence, aapr.region_name;

    return l_return;
  end get_page_items;

  /* ================================================================== */
  /* == get_base_url ================================================== */
  /* ================================================================== */
  function get_base_url(pi_app_id   in number
                      , pi_page_id  in number
                      , pi_base_url in varchar2 default null)
    return varchar2
  as
    l_return varchar2(100);
  begin
    if pi_base_url is not null
      then
        l_return := pi_base_url;
      else
        l_return := 'http://apex.mt-ag.com/';
    end if;
    return l_return;
  end get_base_url;

  /* ================================================================== */
  /* == add_to_collection for items =================================== */
  /* ================================================================== */
  function add_to_collection(pi_dest_collection in t_items
                           , pi_src_collection  in t_items)
    return t_items
  as
    l_dest_count  number;
    l_return      t_items;
  begin
    l_return      := pi_dest_collection;
    l_dest_count  := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;

  /* ================================================================== */
  /* == add_to_collection for interactive grid ======================== */
  /* ================================================================== */
  function add_to_collection(pi_dest_collection in t_ig_items
                           , pi_src_collection  in t_ig_items)
    return t_ig_items
  as
    l_dest_count  number;
    l_return      t_ig_items;
  begin
    l_return      := pi_dest_collection;
    l_dest_count  := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;

  /* ================================================================== */
  /* == add_to_collection for tabular form items ====================== */
  /* ================================================================== */
  function add_to_collection(pi_dest_collection in t_tabform_items
                           , pi_src_collection  in t_tabform_items)
    return t_tabform_items
  as
    l_dest_count  number;
    l_return      t_tabform_items;
  begin
    l_return      := pi_dest_collection;
    l_dest_count  := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;



  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function get_regions(
      pi_app_id       in number,
      pi_page_id      in number,
      pi_region_name  in varchar2 default null
  )
    return t_regions
  as
    l_return t_regions;
  begin
    $IF PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
      $THEN
        select aapr.region_name, aapr.source_type_code
               bulk collect into l_return
          from APEX_APPLICATION_PAGE_REGIONS aapr
          where 1=1
          and aapr.application_id = pi_app_id
          and aapr.page_id        = pi_page_id
          and aapr.region_name    = coalesce(pi_region_name,aapr.region_name)
          order by aapr.display_sequence, aapr.region_name;
    $END

    return l_return;
  end get_regions;


  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function get_ig_regions(pi_regions in t_regions)
    return t_regions
  as
    l_extend_count  number    := 0;
    l_return        t_regions := t_regions();
  begin
    for i in 1..pi_regions.count
    loop
      if pi_regions(i).source_type_code = 'NATIVE_IG'
        then
          l_return.extend;
          l_extend_count := l_extend_count + 1;
          l_return(l_extend_count) := pi_regions(i);
      end if;
    end loop;

    return l_return;
  end get_ig_regions;

  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function get_apex_call_pio_parameter(pi_item          in t_item default null,
                                       pi_ig_item       in t_ig_item default null,
                                       pi_tabform_item  in t_tabform_item default null,
                                       pi_item_or_type  in varchar2
                                      )
    return varchar2
  as
    l_return t_max_vc2;
  begin
    case pi_item_or_type
      when c_items then
        ----------
        -- items
        ----------
        case 
          when pi_item.item_name is not null
            then l_return := pi_item.item_name;
          when pi_ig_item.item_name is not null
            then l_return := '      ' || pi_ig_item.item_name;
          when pi_tabform_item.item_name is not null
            then l_return := '      ' || pi_tabform_item.item_name;
        else
          null;
        end case;
     when c_item_types then     
        ------------------
        -- item_data_type
        ------------------
        case 
          when pi_item.item_data_type is not null
            then l_return := pi_item.item_data_type;
          when pi_ig_item.item_data_type is not null
            then l_return := '      ' || pi_ig_item.item_data_type;
         -- when pi_tabform_item.item_data_type is not null
         --   then l_return := '      ' || pi_tabform_item.item_data_type;
        else
          null;
        end case;
   
    end case;

    return l_return;

  end get_apex_call_pio_parameter;


  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function get_apex_items(pi_items               in t_items default null,
                          pi_ig_items            in t_ig_items default null,
                          pi_tabform_items       in t_tabform_items default null,
                          pi_load_save_or_delete in varchar2 default 'S',
                          pi_item_or_type        in varchar2
  )   
    return clob
  as
    l_return clob;
  begin
    case when pi_items is not null and pi_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' then
          for i in 1..pi_items.count
          loop
            l_return := l_return || get_apex_call_pio_parameter(pi_item         => pi_items(i)
                                                              , pi_item_or_type => pi_item_or_type);

            if not (i = pi_items.count) then
              -- l_return := l_return || ',' || c_cr||'                ';
              l_return := l_return || ','|| c_cr||rpad(' ',16);
            else 
              null; 
            end if;
          end loop;
      end case;

      else
        null;
    end case;

    return l_return;
  end get_apex_items;
      

  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function get_apex_call_script (
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
      pi_is_tab_or_ig            in number default 1,
      pi_load_save_or_delete     in varchar2 default 'S'
  )
    return clob
  as
    l_base_url                    varchar2(100);
    l_items                       t_items := t_items();
    l_apex_items                  clob;
    l_apex_item_types             clob;
    l_return                      clob;

  begin
    l_base_url := get_base_url(pi_app_id => pi_app_id
                             , pi_page_id => pi_page_id
                             , pi_base_url => pi_base_url);

    l_items := get_page_items(pi_app_id       => pi_app_id
                            , pi_page_id      => pi_page_id
                            , pi_region_name  => pi_region_name);

    l_apex_items      := get_apex_items(pi_items               => l_items
                                      , pi_item_or_type        => c_items
                                      , pi_load_save_or_delete => pi_load_save_or_delete);

    l_apex_item_types := get_apex_items(pi_items               => l_items
                                      , pi_item_or_type        => c_item_types
                                      , pi_load_save_or_delete => pi_load_save_or_delete);
    
    l_return := replace_base_url(pi_source_script => c_json_string , pi_base_url => l_base_url);
    l_return := replace_login_yes_no(pi_source_script => l_return, pi_login_yes_no => pi_login_yes_no);
    l_return := replace_username(pi_source_script => l_return, pi_username => pi_username);
    l_return := replace_password(pi_source_script => l_return, pi_password => pi_password);
    l_return := replace_app_id(pi_source_script => l_return , pi_app_id => pi_app_id);
    l_return := replace_page_id(pi_source_script => l_return , pi_page_id => pi_page_id);
    l_return := replace_direct_page(pi_source_script => l_return , pi_direct_yes_no => pi_direct_yes_no);
    l_return := replace_modal_page(pi_source_script => l_return , pi_modal_yes_no => pi_modal_yes_no);
    l_return := replace_items(pi_source_script => l_return, pi_items => l_apex_items);
    l_return := replace_item_types(pi_source_script => l_return, pi_items => l_apex_item_types);
    --
    l_return := replace_screenshot(pi_source_script => l_return , pi_screenshot => pi_screenshot);
    l_return := replace_pdf(pi_source_script => l_return , pi_pdf => pi_pdf);
    l_return := replace_viewport_height(pi_source_script => l_return , pi_viewport_height => pi_viewport_height);
    l_return := replace_viewport_width(pi_source_script => l_return , pi_viewport_width => pi_viewport_width);
    l_return := replace_delay(pi_source_script => l_return , pi_delay => pi_delay);

    return l_return;
  end get_apex_call_script;



  /* ================================================================== */
  /* ================================================================== */
  /* ================================================================== */
  function  get_save_proc_for_apex_proc(
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
      pi_is_tab_or_ig            in number default 1,
      pi_tab_ig_prefix_proc_name in varchar2 default null
   )
    return clob
  as
    l_return clob;
  begin
    case pi_is_tab_or_ig
      when 0
        then
          l_return := get_apex_call_script(
                            pi_base_url                => pi_base_url,
                            pi_login_yes_no            => pi_login_yes_no,
                            pi_username                => pi_username,
                            pi_password                => pi_password,
                            pi_app_id                  => pi_app_id,
                            pi_page_id                 => pi_page_id,
                            pi_direct_yes_no           => pi_direct_yes_no,
                            pi_modal_yes_no            => pi_modal_yes_no,
                            pi_region_name             => pi_region_name,
                            pi_screenshot              => pi_screenshot,
                            pi_pdf                     => pi_pdf,
                            pi_viewport_height         => pi_viewport_height,
                            pi_viewport_width          => pi_viewport_width,
                            pi_delay                   => pi_delay,
                            pi_is_tab_or_ig            => 1,
                            pi_load_save_or_delete     => 'S'
          );

          -- $if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
          --   $then
          --       when 1
          --         then
          --           l_return := get_ig_apex_call_script(pi_app_id              => pi_app_id,
          --                                               pi_page_id             => pi_page_id,
          --                                               pi_load_save_or_delete => 'S',
          --                                               pi_procedure_name      => pi_tab_ig_prefix_proc_name || c_save_proc_name,
          --                                               pi_region_name         => pi_region_name
          --                                               );
          -- $end
      else
        null;
    end case;
    return l_return;
  end get_save_proc_for_apex_proc;


  /* ================================================================== */



  /* ================================================================== */
  /* === in Apex used Functions ======================================= */
  /* ================================================================== */


  /* ================================================================== */
  /* == call from dynamic action "on Change set P10_PAGE_ID" ========== */
  /* ================================================================== */  
  function modal_page_yes_no(
      pi_app_id   in number,
      pi_page_id  in number
  )
    return number
  as
    l_return number;
  begin
    $IF PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
    $THEN
      select count(*) 
        into l_return 
        from apex_application_pages 
        where application_id = pi_app_id 
        and page_id = pi_page_id
        and upper(page_mode) ='MODAL DIALOG';
    $END

    return l_return;
  end; 


  /* ================================================================== */
  /* == call from dynamic action "on Change set P10_PAGE_ID" ========== */
  /* ================================================================== */
  function check_has_tab_ig_on_page(
      pi_app_id   in number,
      pi_page_id  in number
  )
    return number
  as
    l_return number;

  begin
    $IF PKG_APEX_VERSION.c_apex_version_5_0
    $THEN
      select count(*)
        into l_return
        from APEX_APPLICATION_PAGE_REGIONS aapr
       where aapr.application_id = pi_app_id
         and aapr.page_id = pi_page_id
         and aapr.source_type_plugin_name = 'NATIVE_TABFORM';
    $END

    $IF PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
    $THEN
      select count(*)
        into l_return
        from APEX_APPL_PAGE_IGS aaig
        join APEX_APPLICATION_PAGE_REGIONS aapr
          on aapr.region_id = aaig.region_id
       where aaig.application_id = pi_app_id
         and aaig.page_id = pi_page_id
         and aapr.source_type_code = 'NATIVE_IG';
    $END

    return l_return;
  end check_has_tab_ig_on_page;

 /* ================================================================== */
 /* == call from dynamic action "get JSON Code" ====================== */
 /* ================================================================== */
  function get_json_code (
      pi_base_url                in varchar2,
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
    return clob
  as
    l_regions         t_regions;
    l_ig_regions      t_regions;
    l_tabform_regions t_regions;

    l_tab_ig_prefix_proc_name   varchar2(30);
    l_tab_ig_prefixes           apex_application_global.vc_arr2;
    l_tab_ig_pk_cols            apex_application_global.vc_arr2;
    l_count_other_regions_as_ig number := 0;
    l_pk_column                 varchar2(30);

    l_save                      clob;
    l_update                    clob;
    l_delete                    clob;
    l_ig_tab_call_process       clob;

    l_return                    clob;

  begin
    l_regions := get_regions(pi_app_id      => pi_app_id,
                             pi_page_id     => pi_page_id,
                             pi_region_name => pi_region_name
                            );

    -------------------------------------------------
    -- how many regions do we have on a certain page
    -------------------------------------------------
    for i in 1..l_regions.count
    loop
      if l_regions(i).source_type_code = 'NATIVE_IG' or l_regions(i).source_type_code = 'NATIVE_TABFORM'
        then
           null;
        else
          l_count_other_regions_as_ig := l_count_other_regions_as_ig + 1;
      end if;
    end loop;

    if l_count_other_regions_as_ig > 0
      then
        l_return := get_save_proc_for_apex_proc(pi_base_url                => pi_base_url,
                                                   pi_login_yes_no            => pi_login_yes_no,
                                                   pi_username                => pi_username,
                                                   pi_password                => pi_password,
                                                   pi_app_id                  => pi_app_id,
                                                   pi_page_id                 => pi_page_id,
                                                   pi_direct_yes_no           => pi_direct_yes_no,
                                                   pi_modal_yes_no            => pi_modal_yes_no,
                                                   pi_region_name             => pi_region_name,
                                                   pi_screenshot              => pi_screenshot,
                                                   pi_pdf                     => pi_pdf,
                                                   pi_viewport_height         => pi_viewport_height,
                                                   pi_viewport_width          => pi_viewport_width,
                                                   pi_delay                   => pi_delay,
                                                   pi_is_tab_or_ig            => 0,
                                                   pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);
    end if;

    /* ============================================================================ */
    /* ==  Compiler Directive  ==================================================== */
    /* ============================================================================ */
    $if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
      $then
        l_ig_regions := get_ig_regions(pi_regions => l_regions);
        -----------------------------------------------------------------
        --TODO pi_tab_ig_prefix_proc_name, pi_pk_column pk coloumns
        --can be more if we had 2 or more IG on page same for ig_prefix
        -----------------------------------------------------------------
      if l_ig_regions is not null and l_ig_regions.count > 0
        then
          if pi_tab_ig_prefix_proc_name is not null and instr(pi_tab_ig_prefix_proc_name,',') > 0
            then
              l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
            else
              l_tab_ig_prefixes(1) := pi_tab_ig_prefix_proc_name;
          end if;

          for i in 1..l_ig_regions.count
          loop
            if i <= l_tab_ig_prefixes.count  and l_tab_ig_prefixes(i) is not null --pi_tab_ig_prefix_proc_name is not null
              then
                l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; --pi_tab_ig_prefix_proc_name || '_';
              else
                l_tab_ig_prefix_proc_name := 'IG_' || (i) || '_';
            end if;

            l_save :=  get_save_proc_for_apex_proc(pi_base_url                => pi_base_url,
                                                   pi_login_yes_no            => pi_login_yes_no,
                                                   pi_username                => pi_username,
                                                   pi_password                => pi_password,
                                                   pi_app_id                  => pi_app_id,
                                                   pi_page_id                 => pi_page_id,
                                                   pi_direct_yes_no           => pi_direct_yes_no,
                                                   pi_modal_yes_no            => pi_modal_yes_no,
                                                   pi_region_name             => l_ig_regions(i).region_name,
                                                   pi_screenshot              => pi_screenshot,
                                                   pi_pdf                     => pi_pdf,
                                                   pi_viewport_height         => pi_viewport_height,
                                                   pi_viewport_width          => pi_viewport_width,
                                                   pi_delay                   => pi_delay,
                                                   pi_is_tab_or_ig            => 1,
                                                   pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);

            -- l_update :=  get_update_proc_for_apex_proc(pi_app_id                  => pi_app_id,
            --                                            pi_page_id                 => pi_page_id,
            --                                            pi_region_name             => l_ig_regions(i).region_name,
            --                                            pi_is_tab_or_ig            => 1,
            --                                            pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);

            -- l_delete :=  get_del_proc_for_apex_proc(pi_app_id                   => pi_app_id,
            --                                         pi_page_id                  => pi_page_id,
            --                                         pi_region_name              => l_ig_regions(i).region_name,
            --                                         pi_is_tab_or_ig             => 1,
            --                                         pi_tab_ig_prefix_proc_name  => l_tab_ig_prefix_proc_name);

            l_ig_tab_call_process := c_json_string;

            l_ig_tab_call_process := replace_ig_tab_save_call(pi_source_script => l_ig_tab_call_process, pi_save_script => l_save);
           -- l_ig_tab_call_process := replace_ig_tab_update_call(pi_source_script => l_ig_tab_call_process, pi_update_script => l_update);
           -- l_ig_tab_call_process := replace_ig_tab_delete_call(pi_source_script => l_ig_tab_call_process, pi_delete_script => l_delete);

            l_return := l_return || l_ig_tab_call_process;

          end loop;
      end if;
    $end

    return l_return;
  end get_json_code;

  end puppeteer;
  ------------------
  -- end of program
  ------------------