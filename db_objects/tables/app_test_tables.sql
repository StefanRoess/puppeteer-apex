drop table item_values;

create table item_values (
    id              number generated always as identity
  , item_id         number
  , item_name       varchar2 (4000 char) not null
  , item_value      varchar2 (4000 char)
  , item_data_type  varchar2 (4000 char)
  , item_default    varchar2 (4000 char)
  , item_type       varchar2 (4000 char) -- from forms_item or interactive grid column
  , item_static_id  varchar2 (4000 char)
  , is_required     varchar2 (4000 char)
  , region_id       number
  , region_name     varchar2 (4000 char)
  , app_id          number
  , page_id         number
  , constraint      item_values_pk primary key ( id ) enable
)
;
