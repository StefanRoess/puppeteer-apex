
create or replace package body pup_dyn_regions
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
  )
  --------------------------------------------------------------------------------------------
  -- Creates a new breadcrumb
  -- Parameter: 1. p_app_id              => Application_ID
  --            2. p_new_breadcrumb_name => Short_Name for the Breadcrumb
  --            3. p_parent_name         => the parent name for this new breadcrumb
  --            4. p_auth_name           => does this new breadcrumb have a authorization_scheme
  --            5. p_page_id             => a click at this breadcrumb entry will link you to
  --                                        this page.
  --            6. p_breadcrumb_home     => The breadcrumb_home name (Quelle/Source)
  --
  -- Attention: Apex 5 has an extra procedure call "check_api_use_allowed"
  --            in procedure create_menu_option to control the access
  --            for wwv_flow_api.create_menu_option.
  --            You must set the column: runtime_api_usage in table: wwv_flows to 'W'
  --            then you have access to wwv_flow_api.create_menu_option
  --
  --            if there is an error like this:
  --                An API call has been prohibited. Contact your administrator.
  --                Details about this incident are available via debug id "4153".
  --            then:
  --                select *
  --                  from apex_debug_messages
  --                  where page_view_id = NN
  --                  order by message_timestamp asc;
  --
  -- History:
  --  28-Aug-2015 V1.0   Stefan Roess
  --------------------------------------------------------------------------------------------
  IS
    l_parent_region_id   number;
    l_display_sequence   number;
    l_region_name        varchar2(200) := 'Stefan';
    l_parent_region_name varchar2(200) := 'Testschritte';
    l_template_id        number;

  begin
    -------------------------------
    -- set up the APEX environment
    -------------------------------
    wwv_flow_api.set_security_group_id;

    wwv_flow_api.set_version (wwv_flow_api.g_compatable_from_version);

    ------------------------------------------
    -- set the application id and region_name
    ------------------------------------------
    wwv_flow.g_flow_id  := p_app_id;
    l_region_name       := coalesce(p_region_name, l_region_name);

    ---------------------------------------
    -- select parent_region_id
    ---------------------------------------
    select region_id 
      into l_parent_region_id
      from apex_application_page_regions
      where 1=1
      and application_id = p_app_id
      and page_id = p_page_id
      and region_name = l_parent_region_name;

    ----------------------------------------------
    -- max display_sequence for setting a new one
    ----------------------------------------------
    select nvl(max(display_sequence),0) + 10
      into l_display_sequence
      from apex_application_page_regions 
      where 1=1 
      and application_id    = p_app_id 
      and page_id           = p_page_id
      and parent_region_id  = l_parent_region_id;
      
        

     select template_id
        into l_template_id
        from apex_application_page_regions 
        where 1=1 
        and application_id = p_app_id 
        and page_id = p_page_id
        and parent_region_id = l_parent_region_id
        and rownum = 1;



      -- BEGIN
      --    SELECT breadcrumb_id
      --      INTO lv_source_id
      --      FROM apex_application_breadcrumbs
      --     WHERE 1 = 1
      --       AND application_id = p_app_id
      --       AND lower (breadcrumb_name) = lower (p_breadcrumb_home);
      -- EXCEPTION
      --    WHEN OTHERS THEN
      --       lv_source_id := 0;
      -- END;

      -- logger.log('l_parent_region_id:'||l_parent_region_id);
      -- logger.log('l_display_sequence:'||l_display_sequence);
      -- logger.log('l_template_id:'||l_template_id);

      wwv_flow_api.create_page_plug(
           p_flow_id                       => p_app_id
          ,p_page_id                       => p_page_id
          ,p_plug_name                     => l_region_name
          ,p_parent_plug_id                => wwv_flow_api.id(l_parent_region_id)
          ,p_region_template_options       => '#DEFAULT#:t-Region--scrollBody'
          ,p_plug_template                 => wwv_flow_api.id(l_template_id)
          ,p_plug_display_sequence         => l_display_sequence
          ,p_include_in_reg_disp_sel_yn    => 'N'
          ,p_plug_display_point            => 'BODY'
          ,p_plug_query_row_template       => 1
          ,p_plug_query_options            => 'DERIVED_REPORT_COLUMNS'
          ,p_attribute_01                  => 'N'
          ,p_attribute_02                  => 'HTML'
        );
  exception
    when others then
      -- logger.log(DBMS_UTILITY.format_error_backtrace);
      null;

  end create_region;
/* =================================================================================== */
/* =================================================================================== */
/* =================================================================================== */

end pup_dyn_regions;
