-----------------------------
-- which application exists
-----------------------------
select application_id || ' ' || application_name,  application_id
  from apex_applications
  where application_id < 4000
  order by application_id, application_name

-------------
-- all lists
-------------
select list_name, list_id from APEX_APPLICATION_LISTS where application_id = :app_id;

----------------------------------
-- all list entries and its pages
----------------------------------
select text d, LIST_ENTRY_ID r
  from (
          select '('||level||') - '||a.entry_text text, LIST_ENTRY_ID
            from apex_application_list_entries a
            where 1=1
            and a.application_id = :P30_APP_ID
            and a.list_id = :P30_APPLICATION_LIST
            start with a.list_entry_parent_id is null
            connect by prior a.list_entry_id = a.list_entry_parent_id
            order by display_sequence
  );

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

-------------------------
-- occurencies of 'f?p='
-------------------------
select regexp_count(region_source,'f?p='), a.region_source
  from apex_application_page_regions a
  where 1=1
  and application_id =:app_id
  and regexp_count(region_source,'f?p=') > 0;


select regexp_count(region_source,'f?p=')
     , regexp_substr(replace(lower(a.region_source), ':app_id', '#'), '[^:]+', 1, 2) page_ids
     , regexp_substr(replace(lower(a.region_source), ':app_id', '#'), '[^f?p=]+', 1, 2) p
     , a.region_source
     , replace(a.region_source, ':app_id', '#')
  from apex_application_page_regions a
  where 1=1
  and application_id =:app_id
  and regexp_count(region_source,'f?p=') > 0;


select  region_source
       ,regexp_substr (region_source, '[^f?p=]+', 1, 1)    as part_1
       ,regexp_substr (region_source, '[^f?p=]+', 1, 2)    as part_2
       ,regexp_substr (region_source, '[^f?p=]+', 1, 3)    as part_3
       ,regexp_substr (region_source, '[^f?p=]+', 1, 4)    as part_4
  from apex_application_page_regions a
  where 1=1
  and application_id =:app_id
  and regexp_count(region_source,'f?p=') > 0;

select regexp_count(region_source,'f?p=')
     , substr(regexp_substr(a.region_source, '[f\?p=]+*:[[:digit:]]+',1,1),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*:[[:digit:]]+',1,2),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*:[[:digit:]]+',1,3),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*:[[:digit:]]+',1,4),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*',1,1),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*',1,2),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*',1,3),2) digit
     , substr(regexp_substr(a.region_source, '[f\?p=]+*',1,4),2) digit
     --, substr(regexp_substr(a.region_source, ':[[:digit:]]+',1,2),2) digit2
     --, substr(regexp_substr(a.region_source, ':[[:digit:]]+',1,3),2) digit3
     --, substr(regexp_substr(a.region_source, ':[[:digit:]]+',1,4),2) digit4
     , region_source
  from apex_application_page_regions a
  where 1=1
  and application_id =:app_id
  and regexp_count(region_source,'f?p=') > 0;

---
