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
    pi_region_name in varchar2
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
                and pr.region_name    = pi_region_name
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
                and pr.region_name    = pi_region_name
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
    pi_region_name in varchar2
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
                and ic.region_name    = pi_region_name
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
                and ic.region_name    = pi_region_name
                and ic.item_type in ('NATIVE_HIDDEN', 'NATIVE_DISPLAY_ONLY', 'NATIVE_ROW_ACTION', 'NATIVE_ROW_SELECTOR')
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
    l_item_type varchar2(20) := 'IG-Column-Item';

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







  /* clean till here */





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
  function get_region_ids (p_app_id in number, p_page_id in number)
     return varchar2
  ---------------------------------------------------------------------------------------
  -- returns all region_id's for a certain app_id and page_id
  --
  -- History:
  --  16-Jan-2018 V1.0   Stefan Roess
  ---------------------------------------------------------------------------------------
  is
     l_vc_region_ids   apex_application_global.vc_arr2;
     l_string         pup_constants.t_big_vc2;

  begin
    select region_id
           bulk collect into l_vc_region_ids
      from apex_application_page_regions
      where 1=1
      and application_id  = p_app_id
      and page_id         = p_page_id
      order by region_name;

      l_string := apex_util.table_to_string (l_vc_region_ids, ':');
      return (l_string);
  end get_region_ids;


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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
            when upper(aapi.display_as)     = 'NUMBER FIELD'  then 'NUMBER'
            when upper(aapi.item_data_type) = 'VARCHAR'       then 'VARCHAR2'
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

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  function get_regions(
      pi_app_id       in number,
      pi_page_id      in number,
      pi_region_name  in varchar2 default null
  )
    return t_regions
  as
    l_return t_regions;

  begin
    $IF pup_constants.c_apex_version_5_1 or pup_constants.c_apex_version_5_1_greater
    $THEN

        -- if pi_pk_column is not null and instr(pi_pk_column,':') > 0
        --   then
        --     l_tab_ig_pk_cols := APEX_UTIL.STRING_TO_TABLE(p_string => pi_pk_column, p_separator => ':');
        --   else
        --     l_tab_ig_pk_cols(1) := pi_pk_column;
        -- end if;

          -- if i <= l_tab_ig_pk_cols.count and l_tab_ig_pk_cols(i) is not null
          --   then
          --     l_pk_column := l_tab_ig_pk_cols(i);
          --   else
          --     l_pk_column := 'ROWID';    -- l_pk_column entspricht dann dem l_region_name
          -- end if;

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


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  function get_apex_call_pio_parameter(pi_item          in t_item default null,
                                       pi_ig_item       in t_ig_item default null,
                                       pi_tabform_item  in t_tabform_item default null,
                                       pi_item_or_type  in varchar2
                                      )
    return varchar2
  as
    l_return pup_constants.t_max_vc2;

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


  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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
            ----------------------------------------
            -- responsible for items and data_types
            ----------------------------------------
            l_return := l_return || get_apex_call_pio_parameter(pi_item => pi_items(i), pi_item_or_type => pi_item_or_type);

            if not (i = pi_items.count) then
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
      

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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

    l_apex_items := get_apex_items(pi_items               => l_items
                                 , pi_item_or_type        => c_items
                                 , pi_load_save_or_delete => pi_load_save_or_delete);

    l_apex_item_types := get_apex_items(pi_items               => l_items
                                      , pi_item_or_type        => c_item_types
                                      , pi_load_save_or_delete => pi_load_save_or_delete);
    
    l_return := pup_json_string.replace_base_url(pi_source_script => pup_json_string.c_json_string , pi_base_url => l_base_url);
    l_return := pup_json_string.replace_login_yes_no(pi_source_script => l_return, pi_login_yes_no => pi_login_yes_no);
    l_return := pup_json_string.replace_username(pi_source_script => l_return, pi_username => pi_username);
    l_return := pup_json_string.replace_password(pi_source_script => l_return, pi_password => pi_password);
    l_return := pup_json_string.replace_app_id(pi_source_script => l_return , pi_app_id => pi_app_id);
    l_return := pup_json_string.replace_page_id(pi_source_script => l_return , pi_page_id => pi_page_id);
    l_return := pup_json_string.replace_direct_page(pi_source_script => l_return , pi_direct_yes_no => pi_direct_yes_no);
    l_return := pup_json_string.replace_modal_page(pi_source_script => l_return , pi_modal_yes_no => pi_modal_yes_no);
    l_return := pup_json_string.replace_items(pi_source_script => l_return, pi_items => l_apex_items);
    l_return := pup_json_string.replace_item_types(pi_source_script => l_return, pi_items => l_apex_item_types);
    --
    l_return := pup_json_string.replace_screenshot(pi_source_script => l_return , pi_screenshot => pi_screenshot);
    l_return := pup_json_string.replace_pdf(pi_source_script => l_return , pi_pdf => pi_pdf);
    l_return := pup_json_string.replace_viewport_height(pi_source_script => l_return , pi_viewport_height => pi_viewport_height);
    l_return := pup_json_string.replace_viewport_width(pi_source_script => l_return , pi_viewport_width => pi_viewport_width);
    l_return := pup_json_string.replace_delay(pi_source_script => l_return , pi_delay => pi_delay);

    return l_return;
  end get_apex_call_script;



  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
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
      else
        null;
    end case;
    return l_return;
  end get_save_proc_for_apex_proc;

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

  /* =================================================================================== */
  /* =================================================================================== */
  /* =================================================================================== */
  function check_has_tab_ig_on_page(
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
        from APEX_APPL_PAGE_IGS aaig
        join APEX_APPLICATION_PAGE_REGIONS aapr
          on aapr.region_id = aaig.region_id
       where aaig.application_id = pi_app_id
         and aaig.page_id = pi_page_id
         and aapr.source_type_code = 'NATIVE_IG';
    $END

    return l_return;
  end check_has_tab_ig_on_page;


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
    -- todo
    -- übergabe an eine neue Page (Modal), diese listet alle editierbaren Items und editierbare IG Columns auf.

    -- l_regions := get_regions(pi_app_id      => pi_app_id,
    --                          pi_page_id     => pi_page_id,
    --                          pi_region_name => pi_region_name
    --                         );

    -- -------------------------------------------------
    -- -- how many regions do we have on a certain page
    -- -------------------------------------------------
    -- for i in 1..l_regions.count
    -- loop
    --   if l_regions(i).source_type_code = 'NATIVE_IG' or l_regions(i).source_type_code = 'NATIVE_TABFORM'
    --     then
    --        null;
    --     else
    --       l_count_other_regions_as_ig := l_count_other_regions_as_ig + 1;
    --   end if;
    -- end loop;

    -- Stefan Roess
    l_count_other_regions_as_ig := 1;

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

    return l_return;
  end start_json;

------------------
-- end of program
------------------
end pup_main;
