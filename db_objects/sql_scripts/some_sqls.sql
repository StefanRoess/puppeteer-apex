-------------
-- all lists
-------------
select list_name, list_id from APEX_APPLICATION_LISTS where application_id = :app_id;

----------------------------------
-- all list entries and its pages
----------------------------------
select lpad(' ', 2*level) || entry_text List, REGEXP_SUBSTR (a.entry_target, '[^:]+', 1, 2) Page
  from apex_application_list_entries a
  where 1=1
  and a.application_id =:app_id
  and   a.list_name = 'Application Navigation'
  and (condition_type_code != 'NEVER' or condition_type_code is null)
  start with a.list_entry_parent_id is null
  connect by prior a.list_entry_id = a.list_entry_parent_id
  order by display_sequence;

-------------------------
-- all application_pages
-------------------------
select page_id||' - '||page_name pages, page_mode
  from APEX_APPLICATION_PAGES
  where 1=1
  and application_id = :app_id
  order by page_id;

-----------------------------
-- buttons on a certain page
-----------------------------
select label, replace(REGEXP_SUBSTR(redirect_url, '[^:]+', 1, 2), '&APP_PAGE_ID.', page_id) Page
  from APEX_APPLICATION_PAGE_BUTTONS
  where 1=1
  and application_id = :app_id
  and page_Id = :app_page_id;


-------------------------------
-- all items on a certain page
-------------------------------
select item_name, region_name
     from table(
             pup_main.get_edit_ig_items(:app_id, :app_page_id)
           )
union           
select item_name, region_name
     from table(
             pup_main.get_edit_items(:app_id, :app_page_id)
           );