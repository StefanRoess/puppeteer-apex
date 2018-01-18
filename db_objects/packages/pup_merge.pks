create or replace package pup_merge
as
   /******************************************************************************
      NAME:       pup_merge
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        18.01.2018  Stefan Roess     1. Created this package.
   ******************************************************************************/


   /*=============================================================================*/
   /*               Declare public visible types, cursor, exception               */
   /*=============================================================================*/
   f_inserting  constant pls_integer := 0;
   f_updating   constant pls_integer := 1;
   g_update_counter      pls_integer not null := 0;
   g_insert_counter      pls_integer not null := 0;

   function merge_counter (action_in in pls_integer default f_inserting)
      return pls_integer;

   function get_merge_update_count
      return pls_integer;

   function get_merge_update_count (merge_count_in in pls_integer)
      return pls_integer;

   function get_merge_insert_count
      return pls_integer;

   function get_merge_insert_count (merge_count_in in pls_integer)
      return pls_integer;

   procedure reset_counters;
end pup_merge;
