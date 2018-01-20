create or replace package body pup_main
as
  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- Delivers all editable items.
  -- This means no items like readonly, hidden or NATIVE_DISPLAY_ONLY.
  --
  -- History:
  --  17-Jan-2018 V1.0   Stefan Roess
  --
  -- call example:
  -- select *
  --   from table(
  --           pup_main.get_edit_items(:P20_APP_ID, :P20_PAGE_ID, :P20_REGION_NAME)
  --         );
  ---------------------------------------------------------------------------------------
  function get_edit_items(
    pi_app_id      in number,
    pi_page_id     in number,
    pi_region_name in varchar2 default null
  )
    return t_edit_items pipelined
  as
    l_return t_edit_item;

  begin
    for l_i in (
      select item_id, item_name, item_data_type, is_required
           , item_default, item_static_id, region_id, region_name
        from (
              select  pi.item_id,
                      pi.item_name,
                      case
                        when upper(pi.display_as)     = 'NUMBER FIELD'  then 'NUMBER'
                        when upper(pi.item_data_type) = 'VARCHAR'       then 'VARCHAR2'
                        else upper(pi.item_data_type)
                      end item_data_type,
                      pi.is_required, -- Yes, No,
                      pi.item_default,
                      pi.item_name item_static_id,
                      pr.region_id,
                      pr.region_name
                from apex_application_page_items pi
                join apex_application_page_regions pr on (pi.region_id = pr.region_id)
                where 1=1
                and pi.application_id = pr.application_id
                and pr.application_id = pi_app_id
                and pi.page_id        = pr.page_id
                and pi.page_id        = pi_page_id
                and pr.region_name    = coalesce(pi_region_name, pr.region_name)
              minus
              select  pi.item_id,
                      pi.item_name,
                      case
                        when upper(pi.display_as)     = 'NUMBER FIELD'  then 'NUMBER'
                        when upper(pi.item_data_type) = 'VARCHAR'       then 'VARCHAR2'
                        else upper(pi.item_data_type)
                      end item_data_type,
                      pi.is_required, -- Yes, No,
                      pi.item_default,
                      pi.item_name item_static_id,
                      pr.region_id,
                      pr.region_name
                from apex_application_page_items pi
                join apex_application_page_regions pr on (pi.region_id = pr.region_id)
                where 1=1
                and pi.application_id = pr.application_id
                and pr.application_id = pi_app_id
                and pi.page_id        = pr.page_id
                and pi.page_id        = pi_page_id
                and pr.region_name    = coalesce(pi_region_name, pr.region_name)
                and ( pi.display_as_code in ('NATIVE_DISPLAY_ONLY','NATIVE_HIDDEN')
                  or lower(pi.html_form_element_attributes) like '%readonly%'
                  or pi.read_only_condition_type_code = 'ALWAYS'
                )
              )
    )
    loop
      l_return.item_id        := l_i.item_id;
      l_return.item_name      := l_i.item_name;
      l_return.item_data_type := l_i.item_data_type;
      l_return.is_required    := l_i.is_required;
      l_return.item_default   := l_i.item_default;
      l_return.item_static_id := l_i.item_static_id;
      l_return.region_id      := l_i.region_id;
      l_return.region_name    := l_i.region_name;
      pipe row(l_return);
    end loop;

  end get_edit_items;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- Delivers all editable interactive grid items.
  -- This means no items like readonly, hidden or NATIVE_DISPLAY_ONLY.
  --
  -- History:
  --  17-Jan-2018 V1.0   Stefan Roess
  --
  -- call example:
  -- select *
  --   from table(
  --           pup_main.get_edit_ig_items(:P20_APP_ID, :P20_PAGE_ID, :P20_REGION_NAME)
  --         );
  ---------------------------------------------------------------------------------------
  function get_edit_ig_items(
    pi_app_id      in number,
    pi_page_id     in number,
    pi_region_name in varchar2 default null
  )
    return t_edit_ig_items pipelined
  as
    l_return t_edit_ig_item;

  begin
    for l_i in (
      select column_id item_id
           , name item_name
           , data_type item_data_type
           , is_required
           , item_default
           , static_id item_static_id
           , region_id
           , region_name
        from (
              select ic.column_id,
                     ic.name,
                     ic.data_type,
                     ic.is_required,
                     null item_default,
                     ic.static_id,
                     ic.region_id,
                     ic.region_name
                from apex_appl_page_ig_columns ic
                where 1=1
                and ic.application_id = pi_app_id
                and ic.page_id        = pi_page_id
                and ic.region_name    = coalesce(pi_region_name, ic.region_name)
              minus
              select  ic.column_id,
                     ic.name,
                     ic.data_type,
                     ic.is_required,
                     null item_default,
                     ic.static_id,
                     ic.region_id,
                     ic.region_name
                from apex_appl_page_ig_columns ic
                where 1=1
                and ic.application_id = pi_app_id
                and ic.page_id        = pi_page_id
                and ic.region_name    = coalesce(pi_region_name, ic.region_name)
                and (ic.item_type in ('NATIVE_HIDDEN', 'NATIVE_DISPLAY_ONLY', 'NATIVE_ROW_ACTION', 'NATIVE_ROW_SELECTOR')
                 or read_only_condition_type_code = 'ALWAYS')
              )
    )
    loop
      l_return.item_id        := l_i.item_id;
      l_return.item_name      := l_i.item_name;
      l_return.item_data_type := l_i.item_data_type;
      l_return.is_required    := l_i.is_required;
      l_return.item_default   := l_i.item_default;
      l_return.item_static_id := l_i.item_static_id;
      l_return.region_id      := l_i.region_id;
      l_return.region_name    := l_i.region_name;
      pipe row(l_return);
    end loop;

  end get_edit_ig_items;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- is this certain region_name for a certain app_id and page_id an interactive report?
  --
  -- History:
  --  17-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function is_native_ig(
    pi_app_id      in number,
    pi_page_id     in number,
    pi_region_name in varchar2
  )
    return number
  as
    l_return number;

  begin
    select 1
      into l_return
      from apex_application_page_regions pr
      join apex_appl_page_igs ig on (pr.region_id = ig.region_id)
      where 1=1
      and pr.application_id    = pi_app_id
      and pr.page_id           = pi_page_id
      and pr.region_name       = pi_region_name
      and pr.source_type_code  = 'NATIVE_IG';

    return l_return;

  exception
    when no_data_found then
      l_return := 0;
      return l_return;
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- This procedure takes care for any changes in source (src) for Forms-Items
  -- and insert into or modify for item_values
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  procedure merge_item_values  (pi_app_id      in number
                              , pi_page_id     in number
                              , pi_region_name in varchar2)
  as
    l_item_type varchar2(10) := 'Forms-Item';

  begin
    merge into item_values dest
      using (select item_id
                  , item_name
                  , item_data_type
                  , is_required
                  , item_default
                  , item_static_id
                  , region_id
                  , region_name
              from table(get_edit_items(pi_app_id, pi_page_id, pi_region_name))
            ) src
        on (dest.item_id = src.item_id)
      when matched then
        update set dest.item_name       = src.item_name,
                   dest.item_data_type  = src.item_data_type,
                   dest.is_required     = src.is_required,
                   dest.item_default    = src.item_default,
                   dest.item_static_id  = src.item_static_id
      when not matched then
        insert (item_id
              , item_name
              , item_type
              , item_data_type
              , is_required
              , item_default
              , item_static_id
              , region_id
              , region_name
              , app_id, page_id)
          values (src.item_id
                , src.item_name
                , l_item_type
                , src.item_data_type
                , src.is_required
                , src.item_default
                , src.item_static_id
                , src.region_id
                , src.region_name
                , pi_app_id, pi_page_id);
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- This procedure takes care for any changes in source (src) for IG-Column-Item
  -- and insert into or modify for item_values
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  procedure merge_item_ig_values  (pi_app_id      in number
                                 , pi_page_id     in number
                                 , pi_region_name in varchar2)
  as
    l_item_type varchar2(20) := 'IG-Col-Item';

  begin
    merge into item_values dest
      using (select item_id
                  , item_name
                  , item_data_type
                  , is_required
                  , item_default
                  , item_static_id
                  , region_id
                  , region_name
              from table(get_edit_ig_items(pi_app_id, pi_page_id, pi_region_name))
            ) src
        on (dest.item_id = src.item_id)
      when matched then
        update set dest.item_name       = src.item_name,
                   dest.item_data_type  = src.item_data_type,
                   dest.is_required     = src.is_required,
                   dest.item_default    = src.item_default,
                   dest.item_static_id  = src.item_static_id
      when not matched then
        insert (item_id
              , item_name
              , item_type
              , item_data_type
              , is_required
              , item_default
              , item_static_id
              , region_id
              , region_name
              , app_id, page_id)
          values (src.item_id
                , src.item_name
                , l_item_type
                , src.item_data_type
                , src.is_required
                , src.item_default
                , src.item_static_id
                , src.region_id
                , src.region_name
                , pi_app_id, pi_page_id);
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- Deletion of certain values for Forms-Item in table item_values
  --
  -- History:
  --  17-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  procedure delete_item_values  (pi_app_id      in number
                               , pi_page_id     in number
                               , pi_region_name in varchar2)
  as
  begin
    delete from item_values dest
      where 1=1
      and app_id      = pi_app_id
      and page_Id     = pi_page_id
      and region_name = pi_region_name
      and 0 = (select count (1)
                 from table(get_edit_items(pi_app_id, pi_page_id, pi_region_name)) src
                 where 1 = 1
                 and dest.item_id = src.item_id);
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- Deletion of certain values for IG-Column-Item in table item_values
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  procedure delete_item_ig_values  (pi_app_id      in number
                                  , pi_page_id     in number
                                  , pi_region_name in varchar2)
  as
  begin
    delete from item_values dest
      where 1=1
      and app_id      = pi_app_id
      and page_Id     = pi_page_id
      and region_name = pi_region_name
      and 0 = (select count (1)
                 from table(get_edit_ig_items(pi_app_id, pi_page_id, pi_region_name)) src
                 where 1 = 1
                 and dest.item_id = src.item_id);
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- This procedure will be called by page 20 (after header pre-rendering)
  -- pi_dml_flag decides if merging or deletion will be accomplished
  -- l_ig => delivers 1 = Interactive Grid or others (l_ig = 0)
  --
  -- History:
  --  17-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  procedure handle_all_regions(pi_app_id      in number
                             , pi_page_id     in number
                             , pi_region_name in varchar2
                             , pi_dml_flag    in varchar2)
  as
    l_vc_arr_region_name  apex_application_global.vc_arr2;
    l_ig                  number;

  begin
    l_vc_arr_region_name := apex_util.string_to_table (ltrim (pi_region_name, ':'));

    for l_i in 1 .. l_vc_arr_region_name.count
    loop
      ---------------------------------------
      -- is this region an Interactive Grid?
      -- l_ig = 1
      ---------------------------------------
      l_ig := is_native_ig (pi_app_id, pi_page_id, l_vc_arr_region_name(l_i));

      ---------
      -- merge
      ---------
      if pi_dml_flag = 'M' and l_ig = 0 then
        merge_item_values(pi_app_id, pi_page_id, l_vc_arr_region_name(l_i));
      elsif pi_dml_flag = 'M' and l_ig = 1 then
        merge_item_ig_values(pi_app_id, pi_page_id, l_vc_arr_region_name(l_i));
      end if;

      ----------
      -- delete
      ----------
      if pi_dml_flag = 'D' and l_ig = 0 then
        delete_item_values (pi_app_id, pi_page_id, l_vc_arr_region_name(l_i));
      elsif pi_dml_flag = 'D' and l_ig = 1 then
        delete_item_ig_values (pi_app_id, pi_page_id, l_vc_arr_region_name(l_i));
      end if;

    end loop;
  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- l_ig => delivers 1 = Interactive Grid or others (l_ig = 0)
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function handle_json(pi_app_id      in number
                     , pi_page_id     in number
                     , pi_region_name in varchar2)
    return t_item_values
  as
    l_return              t_item_values;
    l_region_name         varchar2(300);
    l_ig                  number;

  begin
    select  id,
            item_id,
            item_name,
            item_value,
            item_data_type,
            item_default,
            item_type,
            item_static_id,
            is_required,
            req_null_value,
            region_id,
            region_name,
            app_id,
            page_id
      bulk collect into l_return
      from item_values
      where 1=1
      and app_id  = pi_app_id
      and page_id = pi_page_id
      and  instr (':'|| pi_region_name || ':', ':'|| region_name||':') > 0;

    return l_return;

  end;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- distinguish between item_name, data_type and item_value
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function get_diff_types(pi_item            in t_item_value default null,
                          pi_item_type_value in varchar2)
    return varchar2
  as
    l_return pup_constants.t_max_vc2;

  begin
    case pi_item_type_value
      ----------
      -- items
      ----------
      when c_items then
        case
          when pi_item.item_name is not null then l_return := c_quot||pi_item.item_name||c_quot;
        else
          null;
        end case;

      ------------------
      -- item_data_type
      ------------------
      when c_item_types then
        case
          when pi_item.item_data_type is not null then l_return := c_quot||pi_item.item_data_type||c_quot;
        else
          null;
        end case;

      --------------
      -- item_value
      --------------
      when c_item_values then
        case
          when pi_item.item_value is not null then l_return := c_quot||pi_item.item_value||c_quot;
        else
          null;
        end case;

    end case;

    return l_return;

  end get_diff_types;


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- with this function the bulk collect of handle_json function
  -- will be executed via the for loop
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function get_apex_items(pi_items               in t_item_values default null,
                          pi_tabform_items       in t_tabform_items default null,
                          pi_item_type_value     in varchar2)
    return clob
  as
    l_return clob;

  begin
    case
      when pi_items is not null and pi_items.count > 0 then
        for i in 1..pi_items.count
        loop
          if pi_items(i).item_value is not null or pi_items(i).req_null_value = 1 then
            ----------------------------------------
            -- responsible for items and data_types
            ----------------------------------------
            l_return := l_return || get_diff_types(pi_item            => pi_items(i)
                                                 , pi_item_type_value => pi_item_type_value);
            ------------------------------------
            -- set a comma but not for the last
            ------------------------------------
            if pi_item_type_value = c_item_values then
              l_return := l_return || ','|| c_cr||rpad(' ', 22);
            else
              l_return := l_return || ','|| c_cr||rpad(' ', 16);
            end if;
          end if;
        end loop;
        l_return := rtrim(l_return, ','|| c_cr||rpad(' ', 1));
    end case;

    return l_return;
  end get_apex_items;


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- this function builds the different json_script elements
  --
  -- History:
  --  18-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function create_json_script (
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
      pi_delay                   in number
  )
    return clob
  as
    l_base_url                    varchar2(100);
    l_items                       t_item_values := t_item_values();
    l_apex_items                  clob;
    l_apex_item_types             clob;
    l_apex_item_values            clob;
    l_return                      clob;

  begin
    l_base_url := get_base_url(pi_app_id => pi_app_id
                             , pi_page_id => pi_page_id
                             , pi_base_url => pi_base_url);

    --------------------------------------------
    -- hier sind im bulk viele Items enthalten.
    --------------------------------------------
    l_items := handle_json(pi_app_id       => pi_app_id
                          ,pi_page_id      => pi_page_id
                          ,pi_region_name  => pi_region_name);

    l_apex_items := get_apex_items(pi_items            => l_items
                                 , pi_item_type_value  => c_items);

    l_apex_item_types := get_apex_items(pi_items           => l_items
                                      , pi_item_type_value => c_item_types);

    l_apex_item_values := get_apex_items(pi_items           => l_items
                                       , pi_item_type_value  => c_item_values);

    l_return := pup_json_string.replace_base_url(pi_source_script => pup_json_string.c_json_string , pi_base_url => l_base_url);
    l_return := pup_json_string.replace_login_yes_no(pi_source_script => l_return, pi_login_yes_no => pi_login_yes_no);
    l_return := pup_json_string.replace_username(pi_source_script => l_return, pi_username => pi_username);
    l_return := pup_json_string.replace_password(pi_source_script => l_return, pi_password => pi_password);
    l_return := pup_json_string.replace_app_id(pi_source_script => l_return , pi_app_id => pi_app_id);
    l_return := pup_json_string.replace_page_id(pi_source_script => l_return , pi_page_id => pi_page_id);
    l_return := pup_json_string.replace_direct_page(pi_source_script => l_return , pi_direct_yes_no => pi_direct_yes_no);
    l_return := pup_json_string.replace_modal_page(pi_source_script => l_return , pi_modal_yes_no => pi_modal_yes_no);

    -------------------------
    -- wiederholdende Aktion
    -------------------------
    l_return := pup_json_string.replace_items(pi_source_script => l_return, pi_items => l_apex_items);
    l_return := pup_json_string.replace_item_types(pi_source_script => l_return, pi_items => l_apex_item_types);
    l_return := pup_json_string.replace_item_values(pi_source_script => l_return, pi_items => l_apex_item_values);
    ---

    l_return := pup_json_string.replace_screenshot(pi_source_script => l_return , pi_screenshot => pi_screenshot);
    l_return := pup_json_string.replace_pdf(pi_source_script => l_return , pi_pdf => pi_pdf);
    l_return := pup_json_string.replace_viewport_height(pi_source_script => l_return , pi_viewport_height => pi_viewport_height);
    l_return := pup_json_string.replace_viewport_width(pi_source_script => l_return , pi_viewport_width => pi_viewport_width);
    l_return := pup_json_string.replace_delay(pi_source_script => l_return , pi_delay => pi_delay);

    return l_return;
  end create_json_script;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  ---------------------------------------------------------------------------------------
  -- This function will be called by Apex, with Click at the Button Create JSON
  -- a dynamic Action "get JSON Code" will be fired.
  --
  -- History:
  --  16-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  function start_json (
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
      pi_delay                   in number
  )
    return clob
  as
    l_return                    clob;

  begin
    l_return := create_json_script(pi_base_url                => pi_base_url,
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
                                   pi_delay                   => pi_delay);

    return l_return;
  end start_json;

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */

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
    $IF pup_constants.c_apex_version_5_1 or pup_constants.c_apex_version_5_1_greater
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

------------------
-- end of program
------------------
end pup_main;
