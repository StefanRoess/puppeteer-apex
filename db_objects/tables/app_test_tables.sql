drop table item_values;

create table item_values (
    id              number generated always as identity
  , item_id         number
  , item_name       varchar2 (300 char) not null
  , item_value      varchar2 (300 char)
  , item_data_type  varchar2 (300 char)
  , item_default    varchar2 (300 char)
  , item_type       varchar2 (300 char) -- from forms_item or interactive grid column
  , item_static_id  varchar2 (300 char)
  , is_required     varchar2 (100 char)
  , region_id       number
  , region_name     varchar2 (300 char)
  , app_id          number
  , page_id         number
  , constraint      item_values_pk primary key ( id ) enable
)
;
