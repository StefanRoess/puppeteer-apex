drop table item_values;

create table item_values (
  id 						number generated always as identity
, item_id       number
, item_name  		varchar2 (200 char) not null
, item_value 		varchar2 (200 char)
, item_type     varchar2  (50 char) -- from forms_item or interactive grid column
, region_id     number
, region_name   varchar2 (500 char)
, app_id        number
, page_id       number
, constraint 		item_values_pk primary key ( id ) enable
)
;
