create or replace package body api_by_apex_items
as
  subtype t_max_vc2 is varchar2(32767);
  c_cr constant varchar2(10) := utl_tcp.crlf;
  c_space constant varchar2(10) := ' ';
  c_space_space constant varchar2(10) := '  ';


-- =============================== TEMPLATES ===============================

c_logger_append_param constant t_max_vc2 := regexp_replace(q'[
  %     logger.append_param(l_params, '#PARAMETER#', #PARAMETER#);]',
  '^\s+% ', null, 1, 0, 'm' );

--c_logger_log_start_end constant t_max_vc2 := q'[  logger.log('#START_END#', l_scope, null, l_params);]';

c_pkg_spec_script constant t_max_vc2 := regexp_replace(q'[
  % CREATE OR REPLACE PACKAGE #PKG_NAME#
  % AS
  %   #FUNC_PROC#
  % END #PKG_NAME#;
  % /

  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_pkg_body_script constant t_max_vc2 := regexp_replace(q'[
  % CREATE OR REPLACE PACKAGE BODY #PKG_NAME#
  % AS
  %   #FUNC_PROC#
  % END #PKG_NAME#;
  % /
  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_pkg_body_with_logger_script constant t_max_vc2  := regexp_replace(q'[
  % CREATE OR REPLACE PACKAGE BODY #PKG_NAME#
  % AS
  %   GC_SCOPE_PREFIX CONSTANT VARCHAR2(31) := LOWER($$plsql_unit) || '.';
  %   #FUNC_PROC#
  % END #PKG_NAME#;
  % /
  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_procecure_body_script constant t_max_vc2 := regexp_replace(q'[
  % PROCEDURE #PROCEDURENAME#
  %   (
  % #PARAMETER#
  %   )
  %   IS
  %   BEGIN  
  %     #SQL_SAVE_LOAD_DELETE#  
  %     EXCEPTION
  %       WHEN OTHERS THEN
  %         RAISE;
  %   END #PROCEDURENAME#;
  % 
  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_procecure_body_logger_script constant t_max_vc2 := regexp_replace(q'[
  % PROCEDURE #PROCEDURENAME#
  %   (
  % #PARAMETER#
  %   )
  %   IS
  %     L_SCOPE LOGGER_LOGS.SCOPE%TYPE := GC_SCOPE_PREFIX || '#PROCEDURENAME#';
  %     L_PARAMS LOGGER.TAB_PARAM; 
  %   BEGIN
  % #PI_PIO#  
  %     logger.log('START', l_scope, null, l_params);
  %     #SQL_SAVE_LOAD_DELETE#
  %     logger.log('END', l_scope, null, l_params);
  % 
  % #PO_PIO#
  %     EXCEPTION
  %         WHEN OTHERS THEN
  %           LOGGER.LOG_ERROR('Unhandled Exception', L_SCOPE, NULL, L_PARAMS);
  %           RAISE;  
  %   END #PROCEDURENAME#;
  % 
  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_procecure_spec_script constant t_max_vc2 := regexp_replace(q'[
  % PROCEDURE #PROCEDURENAME#
  %   (
  % #PARAMETER#
  %   );
  %  
  ]',
  '^\s+% ', null, 1, 0, 'm' );

c_apex_call_script constant t_max_vc2 := regexp_replace(q'[
% #PKG_NAME#.#PROCEDURENAME#
    (
#FUNC_PROC#
    );
 
]',
'^\s+% ', null, 1, 0, 'm' );

c_ig_tab_form_gen_call_script constant t_max_vc2 := regexp_replace(q'[
BEGIN  
  CASE :APEX$ROW_STATUS  
    WHEN 'C' THEN 
    #IG_TAB_SAVE_CALL#
    WHEN 'U' THEN  
    #IG_TAB_UPDATE_CALL# 
    WHEN 'D' THEN  
    #IG_TAB_DELETE_CALL#
  END CASE;  
END;  
 
]',
'^\s+% ', null, 1, 0, 'm' );

--man = Manuel
c_ig_tab_form_man_call_script constant t_max_vc2 := regexp_replace(q'[
% BEGIN  
%      CASE :APEX$ROW_STATUS  
%      WHEN 'C' THEN  
%          INSERT INTO #TABLE_NAME# (#COLUMN_NAME#)--EMP ( EMPNO, ENAME, DEPTNO )  
%          VALUES (#TAB_FORM_IG_PRM#)--( :EMPNO, :ENAME, :DEPTNO )  
%          RETURNING ROWID INTO :ROWID;  
%      WHEN 'U' THEN  
%          UPDATE #TABLE_NAME#  --EMP  
%             SET #COLUMN_NAME#  = :#COLUMN_NAME# -- ENAME = :ENAME
%           WHERE ROWID  = :ROWID;  
%      WHEN 'D' THEN  
%          DELETE #TABLE_NAME# --EMP  
%          WHERE ROWID = :ROWID;  
%      END CASE;  
% END;   
% 
]',
'^\s+% ', null, 1, 0, 'm' );

c_sql_update_script constant t_max_vc2 := regexp_replace(q'[
  % UPDATE #TABLE_NAME#
  % SET 
  %   #COL_EXPRESSION#
  % WHERE #PK_COL_PK_ITEM#;
  % 
  ]',
  '^\s+% ', null, 1, 0, 'm' );




-- =============================== TEMPLATE REPLACE FUNCTIONS ===============================

  function replace_pkg_name( pi_source_script in clob, pi_pkg_name in varchar2 )
  return clob
  as
  begin
    return replace(pi_source_script, '#PKG_NAME#', pi_pkg_name);
  end replace_pkg_name;

  function replace_procedure_name(pi_source_script in clob, pi_procedure_name in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#PROCEDURENAME#', pi_procedure_name);
  end replace_procedure_name;

  function replace_func_proc( pi_source_script in clob, pi_func_proc in clob )
  return clob
  as
  begin
    return replace(pi_source_script, '#FUNC_PROC#', pi_func_proc);
  end replace_func_proc;

  function replace_parameter( pi_source_script in clob, pi_parameter in clob )
  return clob
  as
  begin
    return replace(pi_source_script, '#PARAMETER#', pi_parameter);
  end replace_parameter;

  function replace_start_end(pi_source_script in clob, pi_start_end in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#START_END#', pi_start_end);
  end replace_start_end;

  function replace_pi_pio(pi_source_script in clob, pi_logger_parameter in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#PI_PIO#', pi_logger_parameter);
  end replace_pi_pio;

  function replace_sql_save_load_delete(pi_source_script in clob, pi_sql_save_load_delete in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#SQL_SAVE_LOAD_DELETE#', pi_sql_save_load_delete);
  end replace_sql_save_load_delete;

  function replace_po_pio(pi_source_script in clob, pi_logger_parameter in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#PO_PIO#', pi_logger_parameter);
  end replace_po_pio;

  function replace_table_name(pi_source_script in clob, pi_table_name in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#TABLE_NAME#', pi_table_name);
  end replace_table_name;

  function replace_col_expression(pi_source_script in clob, pi_col_expression in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#COL_EXPRESSION#', pi_col_expression);
  end replace_col_expression;  

  function replace_pk_col_pk_item(pi_source_script in clob, pi_pk_col_pk_item in varchar2)
  return clob
  as
  begin
    return replace(pi_source_script, '#PK_COL_PK_ITEM#', pi_pk_col_pk_item);
  end replace_pk_col_pk_item;  

  function replace_ig_tab_save_call( pi_source_script in clob, pi_save_script in varchar2 )
  return clob
  as
  begin
    return replace(pi_source_script, '#IG_TAB_SAVE_CALL#', pi_save_script);
  end replace_ig_tab_save_call;

  function replace_ig_tab_update_call( pi_source_script in clob, pi_update_script in varchar2 )
  return clob
  as
  begin
    return replace(pi_source_script, '#IG_TAB_UPDATE_CALL#', pi_update_script);
  end replace_ig_tab_update_call;

  function replace_ig_tab_delete_call( pi_source_script in clob, pi_delete_script in varchar2 )
  return clob
  as
  begin
    return replace(pi_source_script, '#IG_TAB_DELETE_CALL#', pi_delete_script);
  end replace_ig_tab_delete_call;



  function get_data_type(pi_item_data_type in varchar2)
  return varchar2
  as
    l_return varchar2(30);
  begin
    case pi_item_data_type
--APEX 5.1.x
      when 'NATIVE_DISPLAY_IMAGE'    then  l_return := 'BLOB';
      when 'NATIVE_FILE'             then  l_return := 'BLOB';
      when 'NATIVE_RICH_TEXT_EDITOR' then  l_return := 'CLOB'; 
      when 'NATIVE_DATE_PICKER'      then  l_return := 'DATE';
      when 'NATIVE_SELECT_LIST'      then  l_return := 'NUMBER'; -- often number can be a varchar2 too
      when 'NATIVE_NUMBER_FIELD'     then  l_return := 'NUMBER';
      when 'NATIVE_RADIOGROUP'       then  l_return := 'NUMBER';
      when 'NATIVE_AUTO_COMPLETE'    then  l_return := 'NUMBER';
      when 'NATIVE_HIDDEN'           then  l_return := 'NUMBER'; -- can be a number too
      when 'NATIVE_TEXT_FIELD'       then  l_return := 'VARCHAR2';
      when 'NATIVE_TEXTAREA'         then  l_return := 'VARCHAR2';
      when 'NATIVE_COLOR_PICKER'     then  l_return := 'VARCHAR2';
      when 'NATIVE_DISPLAY_ONLY'     then  l_return := 'VARCHAR2';
      when 'NATIVE_LIST_MANAGER'     then  l_return := 'VARCHAR2'; -- multi number with seperator (1,2,3)
      when 'NATIVE_SHUTTLE'          then  l_return := 'VARCHAR2'; --multi number with seperator (1,2,3)
      when 'NATIVE_YES_NO'           then  l_return := 'VARCHAR2'; --maybe number?
--APEX 5.0.x
      when 'TEXT'                    then  l_return := 'VARCHAR2';
      when 'ESCAPE_SC'               then  l_return := 'VARCHAR2';
      when 'NUMBER'                  then  l_return := 'NUMBER';
      when 'HIDDEN'                  then  l_return := 'NUMBER';
      when 'SELECT_LIST'             then  l_return := 'NUMBER';
      when 'TEXTAREA'                then  l_return := 'VARCHAR2';

      else
        l_return := 'MANUAL_DEFINITION';
    end case;
    return l_return;
  end get_data_type;

  function get_pkg_name(pi_app_id in number, pi_page_id in number, pi_pkg_name in varchar2 default null)
  return varchar2
  as
    l_return varchar2(30);
  begin
    if pi_pkg_name is not null
      then 
        l_return := pi_pkg_name;
      else
        l_return := 'A' || to_char(pi_app_id, 'FM000009') || '_' || 'P' || to_char(pi_page_id, 'FM0009') || '_PKG';
    end if;    
    return l_return;
  end get_pkg_name;

  function get_item_default_value(pi_item in t_item)
  return varchar2
  as
   l_return varchar2(255);
  begin
    if pi_item.item_default is not null 
      then
        l_return := l_return || '  DEFAULT ' || case when pi_item.item_data_type is not null 
                                                  then pi_item.item_data_type 
                                                  else get_data_type(pi_item_data_type => pi_item.display_as_code)
                                                end;
      else 
        l_return := l_return || '  DEFAULT NULL';
    end if;
    return l_return;
  end get_item_default_value;

  function get_parameter_formated(pi_parameter in varchar2, pi_formated_by in varchar2)
  return varchar2
  as
    l_max_length number;
    l_parameter_length number;
    l_return varchar2(255);
  begin
    l_max_length := 30;
    l_parameter_length := length(pi_parameter);

    if l_parameter_length  < l_max_length
      then
        l_return := rpad(pi_parameter, l_max_length) || c_space_space || pi_formated_by;      
      else 
        l_return := substr(pi_parameter,1, l_max_length) || c_space_space || pi_formated_by;
    end if;
    return l_return;
  end get_parameter_formated;


  -- =============================== PARAMETER ===============================

  function get_logger_pio_item(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null)
  return varchar2
  as
    l_return varchar2(255);
  begin
    case
      when pi_item.item_name is not null
        then l_return := 'PIO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_');
      when pi_ig_item.item_name is not null
        then l_return := 'PIO_' || pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := 'PIO_' || pi_tabform_item.item_name;
    end case;
    return l_return;
  end get_logger_pio_item;

  function get_logger_pi_item(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null)
  return varchar2
  as
    l_return varchar2(255);
  begin
    case
      when pi_item.item_name is not null
        then l_return := 'PI_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_');
      when pi_ig_item.item_name is not null
        then l_return := 'PI_' || pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := 'PI_' || pi_tabform_item.item_name;
    end case;
    return l_return;
  end get_logger_pi_item;

  function get_logger_po_item(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null)
  return varchar2
  as
    l_return varchar2(255);
  begin
    case
      when pi_item.item_name is not null
        then l_return := 'PO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_');
      when pi_ig_item.item_name is not null
        then l_return := 'PO_' || pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := 'PO_' || pi_tabform_item.item_name;
    end case;
    return l_return;
  end get_logger_po_item; 

  function get_pio_parameter(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null) 
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case
      when pi_item.item_name is not null
        then
          l_return := '    ' || get_parameter_formated('PIO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), ' IN OUT NOCOPY ') || case when pi_item.item_data_type is not null 
                                                                                                                                                    then pi_item.item_data_type 
                                                                                                                                                    else get_data_type(pi_item_data_type => pi_item.display_as_code)
                                                                                                                                                  end;
      when pi_ig_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PIO_' || pi_ig_item.item_name, ' IN OUT NOCOPY ') || pi_ig_item.item_data_type;

      when pi_tabform_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PIO_' || pi_tabform_item.item_name, ' IN OUT NOCOPY ') || get_data_type(pi_item_data_type => pi_tabform_item.display_as_code);
    end case;
    return l_return;
  end get_pio_parameter;

  function get_pi_parameter(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null)
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case
      when pi_item.item_name is not null
        then
          l_return := '    ' || get_parameter_formated('PI_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), ' IN ') || case when pi_item.item_data_type is not null 
                                                                                                                                        then pi_item.item_data_type 
                                                                                                                                        else get_data_type(pi_item_data_type => pi_item.display_as_code)
                                                                                                                                      end;
      when pi_ig_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PI_' || pi_ig_item.item_name, ' IN ') || pi_ig_item.item_data_type;

      when pi_tabform_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PI_' || pi_tabform_item.item_name, ' IN ') || get_data_type(pi_item_data_type => pi_tabform_item.display_as_code);
    end case;

    return l_return;
  end get_pi_parameter;

  function get_po_parameter(pi_item in t_item default null, pi_ig_item in t_ig_item default null, pi_tabform_item in t_tabform_item default null)
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case
      when pi_item.item_name is not null
        then
          l_return := '    ' || get_parameter_formated('PO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), ' OUT NOCOPY ') || case when pi_item.item_data_type is not null 
                                                                                                                                                then pi_item.item_data_type 
                                                                                                                                                else get_data_type(pi_item_data_type => pi_item.display_as_code)
                                                                                                                                              end;
      when pi_ig_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PO_' || pi_ig_item.item_name, ' OUT ') || pi_ig_item.item_data_type;

      when pi_tabform_item.item_name is not null
        then l_return := '    ' || get_parameter_formated('PO_' || pi_tabform_item.item_name, ' OUT ') ||  get_data_type(pi_item_data_type => pi_tabform_item.display_as_code);
    end case;
    return l_return;
  end get_po_parameter;

 function get_apex_call_pio_parameter(pi_item in t_item default null,
                                      pi_ig_item in t_ig_item default null,
                                      pi_tabform_item in t_tabform_item default null
                                     )
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case 
      when pi_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PIO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), '=> :') ||  pi_item.item_name;
      when pi_ig_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PIO_' || pi_ig_item.item_name, '=> :') ||  pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PIO_' || pi_tabform_item.item_name, '=> :') ||  pi_tabform_item.item_name;
    else
      null;
    end case;
    return l_return;
  end get_apex_call_pio_parameter;

  function get_apex_call_pi_parameter(pi_item in t_item default null,
                                      pi_ig_item in t_ig_item default null,
                                      pi_tabform_item in t_tabform_item default null
                                     )
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case
      when pi_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PI_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), '=> :') ||  pi_item.item_name;
      when pi_ig_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PI_' || pi_ig_item.item_name, '=> :') ||  pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PI_' || pi_tabform_item.item_name, '=> :') ||  pi_tabform_item.item_name;
      else
        null;
    end case;
    return l_return;
  end get_apex_call_pi_parameter;

  function get_apex_call_po_parameter(pi_item in t_item default null,
                                      pi_ig_item in t_ig_item default null,
                                      pi_tabform_item in t_tabform_item default null
                                     )
  return varchar2
  as
    l_return t_max_vc2;
  begin
    case 
      when pi_item.item_name is not null 
        then l_return := '      ' || get_parameter_formated('PO_' || replace(pi_item.item_name, 'P' || pi_item.page_id || '_'), '=> :') ||  pi_item.item_name;
      when pi_ig_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PO_' || pi_ig_item.item_name, '=> :') ||  pi_ig_item.item_name;
      when pi_tabform_item.item_name is not null
        then l_return := '      ' || get_parameter_formated('PO_' || pi_tabform_item.item_name, '=> :') ||  pi_tabform_item.item_name;
      else
        null;
    end case;
    return l_return;
  end get_apex_call_po_parameter;


  -- =============================== SCRIPT FUNCTIONS ===============================

function get_parameter_script(pi_items in t_items default null,
                              pi_ig_items in t_ig_items default null,
                              pi_tabform_items in t_tabform_items default null,
                              pi_load_save_or_delete in varchar2,
                              pi_pk_item in varchar2 default null)
  return clob
  as
    l_return clob;
  begin
    case
      when  pi_items is not null and pi_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pio_parameter(pi_item => pi_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_item => pi_items(i));
                        l_return := l_return || get_item_default_value(pi_item  => pi_items(i));
                    end if; 

                    if not (i = pi_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_pio_parameter(pi_item => pi_items(i));

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;
        
        when 'L'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pi_parameter(pi_item => pi_items(i)) ;
                      else
                        l_return := l_return || get_po_parameter(pi_item => pi_items(i));
                    end if; 

                    if not (i = pi_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_pio_parameter(pi_item => pi_items(i));

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_items.count
                    loop
                      if pi_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_pi_parameter(pi_item => pi_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_item => pi_items(i)) ;

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pi_parameter(pi_item => pi_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_item => pi_items(i));
                        l_return := l_return || get_item_default_value(pi_item  => pi_items(i));
                    end if; 

                    if not (i = pi_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_item => pi_items(i));

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;
      end case;

      when  pi_ig_items is not null and pi_ig_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_ig_items.count
                  loop
                    if pi_ig_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pio_parameter(pi_ig_item => pi_ig_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i));
                        --l_return := l_return || get_item_default_value(pi_ig_item  => pi_ig_items(i));
                    end if; 

                    if not (i = pi_ig_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_ig_items.count
                loop
                  l_return := l_return || get_pio_parameter(pi_ig_item => pi_ig_items(i));

                  if not (i = pi_ig_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_ig_items.count
                    loop
                      if pi_ig_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_ig_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i)) ;

                  if not (i = pi_ig_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_ig_items.count
                  loop
                    if pi_ig_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i));
                        --l_return := l_return || get_item_default_value(pi_ig_item  => pi_ig_items(i));
                    end if; 

                    if not (i = pi_ig_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_ig_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_ig_item => pi_ig_items(i));

                  if not (i = pi_ig_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;
      end case;

      when  pi_tabform_items is not null and pi_tabform_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_tabform_items.count
                  loop
                    if pi_tabform_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pio_parameter(pi_tabform_item => pi_tabform_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i));
                        --l_return := l_return || get_item_default_value(pi_ig_item  => pi_ig_items(i));
                    end if; 

                    if not (i = pi_tabform_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_tabform_items.count
                loop
                  l_return := l_return || get_pio_parameter(pi_tabform_item => pi_tabform_items(i));

                  if not (i = pi_tabform_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_tabform_items.count
                    loop
                      if pi_tabform_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_tabform_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;

                  if not (i = pi_tabform_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_tabform_items.count
                  loop
                    if pi_tabform_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;
                      else
                        l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i));
                        --l_return := l_return || get_item_default_value(pi_ig_item  => pi_ig_items(i));
                    end if; 

                    if not (i = pi_tabform_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_tabform_items.count
                loop
                  l_return := l_return || get_pi_parameter(pi_tabform_item => pi_tabform_items(i));

                  if not (i = pi_tabform_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;
      end case;
      else
       null;
    end case;
 
    return l_return;
  end get_parameter_script;

  function get_apex_call_parameter_script(pi_items in t_items default null,
                                          pi_ig_items in t_ig_items default null,
                                          pi_tabform_items in t_tabform_items default null,
                                          pi_load_save_or_delete in varchar2,
                                          pi_pk_item in varchar2 default null)
  return clob
  as
    l_return clob;
  begin
    case when pi_items is not null and pi_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_apex_call_pio_parameter(pi_item => pi_items(i)) ;
                      else
                        l_return := l_return || get_apex_call_pi_parameter(pi_item => pi_items(i));
                    end if; 

                    if not (i = pi_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_apex_call_pio_parameter(pi_item => pi_items(i));

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;
        
        when 'L'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_apex_call_pi_parameter(pi_item => pi_items(i)) ;
                      else
                        l_return := l_return || get_apex_call_po_parameter(pi_item => pi_items(i));
                    end if; 

                    if not (i = pi_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_apex_call_pio_parameter(pi_item => pi_items(i));

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_items.count
                    loop
                      if pi_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_apex_call_pi_parameter(pi_item => pi_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_items.count
                loop
                  l_return := l_return || get_apex_call_pi_parameter(pi_item => pi_items(i)) ;

                  if not (i = pi_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
            then
              for i in 1..pi_items.count
              loop
                l_return := l_return || get_apex_call_pi_parameter(pi_item => pi_items(i)) ;

                if not (i = pi_items.count) 
                  then
                    l_return := l_return || ',' || c_cr;
                  else null; 
                end if;
              end loop;
      end case;

      when pi_ig_items is not null and pi_ig_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_ig_items.count
                  loop
                    if pi_ig_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_apex_call_pio_parameter(pi_ig_item => pi_ig_items(i)) ;
                      else
                        l_return := l_return || get_apex_call_pi_parameter(pi_ig_item => pi_ig_items(i));
                    end if; 

                    if not (i = pi_ig_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_ig_items.count
                loop
                  l_return := l_return || get_apex_call_pio_parameter(pi_ig_item => pi_ig_items(i));

                  if not (i = pi_ig_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_ig_items.count
                    loop
                      if pi_ig_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_apex_call_pi_parameter(pi_ig_item => pi_ig_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_ig_items.count
                loop
                  l_return := l_return || get_apex_call_pi_parameter(pi_ig_item => pi_ig_items(i)) ;

                  if not (i = pi_ig_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
            then
              for i in 1..pi_ig_items.count
              loop
                l_return := l_return || get_apex_call_pi_parameter(pi_ig_item => pi_ig_items(i)) ;

                if not (i = pi_ig_items.count) 
                  then
                    l_return := l_return || ',' || c_cr;
                  else null; 
                end if;
              end loop;
      end case;


      when pi_tabform_items is not null and pi_tabform_items.count > 0 then
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_tabform_items.count
                  loop
                    if pi_tabform_items(i).item_name = pi_pk_item
                      then
                        l_return := l_return || get_apex_call_pio_parameter(pi_tabform_item => pi_tabform_items(i)) ;
                      else
                        l_return := l_return || get_apex_call_pi_parameter(pi_tabform_item => pi_tabform_items(i));
                    end if; 

                    if not (i = pi_tabform_items.count) 
                      then
                        l_return := l_return || ',' || c_cr;
                      else null; 
                    end if;
                  end loop;
              
              else
                for i in 1..pi_tabform_items.count
                loop
                  l_return := l_return || get_apex_call_pio_parameter(pi_tabform_item => pi_tabform_items(i));

                  if not (i = pi_tabform_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_tabform_items.count
                    loop
                      if pi_tabform_items(i).item_name = pi_pk_item
                        then
                          l_return := l_return || get_apex_call_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_tabform_items.count
                loop
                  l_return := l_return || get_apex_call_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;

                  if not (i = pi_tabform_items.count) 
                    then
                      l_return := l_return || ',' || c_cr;
                    else null; 
                  end if;
                end loop;
              end case;

          when 'U'
            then
              for i in 1..pi_tabform_items.count
              loop
                l_return := l_return || get_apex_call_pi_parameter(pi_tabform_item => pi_tabform_items(i)) ;

                if not (i = pi_tabform_items.count) 
                  then
                    l_return := l_return || ',' || c_cr;
                  else null; 
                end if;
              end loop;
      end case;      

      else
       null;
    end case;
 
    return l_return;
  end get_apex_call_parameter_script;

function get_logger_parameter(pi_items in t_items, pi_load_save_or_delete in varchar2, pi_pk_item in varchar2 default null)
  return t_items
  as
    l_return t_items := t_items();
  begin
      case pi_load_save_or_delete
        when 'S' 
          then

            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pio_item(pi_item => pi_items(i));
                      else
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                    end if; 
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return.extend;
                  l_return(i).item_name :=  get_logger_pio_item(pi_item => pi_items(i));
                end loop;
            end case;
        
        when 'L'
          then
            case
              when pi_pk_item is not null
                then 
                  for i in 1..pi_items.count
                  loop
                    if pi_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                      else
                        l_return.extend;
                        l_return(i).item_name := get_logger_po_item(pi_item => pi_items(i));
                    end if; 
                  end loop;
              
              else
                for i in 1..pi_items.count
                loop
                  l_return.extend;
                  l_return(i).item_name := get_logger_pio_item(pi_item => pi_items(i));
                end loop;
            end case;

          when 'D'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_items.count
                    loop
                      if pi_items(i).item_name = pi_pk_item
                        then
                          l_return.extend;
                          l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                        else
                          null;
                      end if;
                    end loop;

              else
                for i in 1..pi_items.count
                loop
                  l_return.extend;
                  l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                end loop;
              end case;

          when 'U'
            then
              case
                when pi_pk_item is not null
                  then
                    for i in 1..pi_items.count
                    loop
                      l_return.extend;
                      l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                    end loop;

              else
                for i in 1..pi_items.count
                loop
                  l_return.extend;
                  l_return(i).item_name := get_logger_pi_item(pi_item => pi_items(i));
                end loop;
              end case;
          else
           null;
      end case;
 
    return l_return;
  end get_logger_parameter;

  function get_logger_parameter(pi_ig_items in t_ig_items, pi_load_save_or_delete in varchar2, pi_pk_item in varchar2 default null)
  return t_ig_items
  as
    l_return t_ig_items := t_ig_items();
  begin
    case pi_load_save_or_delete
      when 'S' 
        then

          case
            when pi_pk_item is not null
              then 
                for i in 1..pi_ig_items.count
                loop
                  if pi_ig_items(i).item_name = pi_pk_item
                    then
                      l_return.extend;
                      l_return(i).item_name := get_logger_pio_item(pi_ig_item => pi_ig_items(i));
                    else
                      l_return.extend;
                      l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i));
                  end if; 
                end loop;
            
            else
              for i in 1..pi_ig_items.count
              loop
                l_return.extend;
                l_return(i).item_name :=  get_logger_pio_item(pi_ig_item => pi_ig_items(i));
              end loop;
          end case;

        when 'D'
          then
            case
              when pi_pk_item is not null
                then
                  for i in 1..pi_ig_items.count
                  loop
                    if pi_ig_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i));
                      else
                        null;
                    end if;
                  end loop;

            else
              for i in 1..pi_ig_items.count
              loop
                l_return.extend;
                l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i));
              end loop;
            end case;

        when 'U'
          then
            case
              when pi_pk_item is not null
                then
                  for i in 1..pi_ig_items.count
                  loop
                    if pi_ig_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i));
                      else
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i)); --DOUBLE CODE FIX That
                    end if;
                  end loop;

            else
              for i in 1..pi_ig_items.count
              loop
                l_return.extend;
                l_return(i).item_name := get_logger_pi_item(pi_ig_item => pi_ig_items(i));
              end loop;
            end case;
      else
        null;
    end case;
 
    return l_return;
  end get_logger_parameter;

  function get_logger_parameter(pi_tabform_items in t_tabform_items, pi_load_save_or_delete in varchar2, pi_pk_item in varchar2 default null)
  return t_tabform_items
  as
    l_return t_tabform_items := t_tabform_items();
  begin
    case pi_load_save_or_delete
      when 'S' 
        then

          case
            when pi_pk_item is not null
              then 
                for i in 1..pi_tabform_items.count
                loop
                  if pi_tabform_items(i).item_name = pi_pk_item
                    then
                      l_return.extend;
                      l_return(i).item_name := get_logger_pio_item(pi_tabform_item => pi_tabform_items(i));
                    else
                      l_return.extend;
                      l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i));
                  end if; 
                end loop;
            
            else
              for i in 1..pi_tabform_items.count
              loop
                l_return.extend;
                l_return(i).item_name :=  get_logger_pio_item(pi_tabform_item => pi_tabform_items(i));
              end loop;
          end case;

        when 'D'
          then
            case
              when pi_pk_item is not null
                then
                  for i in 1..pi_tabform_items.count
                  loop
                    if pi_tabform_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i));
                      else
                        null;
                    end if;
                  end loop;

            else
              for i in 1..pi_tabform_items.count
              loop
                l_return.extend;
                l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i));
              end loop;
            end case;

        when 'U'
          then
            case
              when pi_pk_item is not null
                then
                  for i in 1..pi_tabform_items.count
                  loop
                    if pi_tabform_items(i).item_name = pi_pk_item
                      then
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i));
                      else
                        l_return.extend;
                        l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i)); --DOUBLE CODE FIX That
                    end if;
                  end loop;

            else
              for i in 1..pi_tabform_items.count
              loop
                l_return.extend;
                l_return(i).item_name := get_logger_pi_item(pi_tabform_item => pi_tabform_items(i));
              end loop;
            end case;
      else
        null;
    end case;
 
    return l_return;
    end get_logger_parameter;
  
  
  function split_logger_parameter(pi_items in t_items, pi_split_value in varchar2)
  return t_items
  as
    l_count number;
    l_created_idx_count number;
    l_return t_items := t_items();
  begin
    l_count := 0;
    l_created_idx_count := 0;
    for rec in 1..pi_items.count
    loop
      if pi_items(rec).item_name like pi_split_value escape '!'
      then
        l_count := l_count + 1;
      end if;
    end loop;
     
    if l_count > 0
      then
        for i in 1..pi_items.count
        loop
          if pi_items(i).item_name like pi_split_value escape '!'
            then
              l_created_idx_count := l_created_idx_count + 1;
              l_return.extend;
              l_return(l_created_idx_count) := pi_items(i);
          end if;
        end loop;
      end if;

    return l_return;
  end split_logger_parameter;

  function split_logger_parameter(pi_ig_items in t_ig_items, pi_split_value in varchar2)
  return t_ig_items
  as
    l_count number;
    l_created_idx_count number;
    l_return t_ig_items := t_ig_items();
  begin
    l_count := 0;
    l_created_idx_count := 0;
    for rec in 1..pi_ig_items.count
    loop
      if pi_ig_items(rec).item_name like pi_split_value escape '!'
      then
        l_count := l_count + 1;
      end if;
    end loop;
     
    if l_count > 0
      then
        for i in 1..pi_ig_items.count
        loop
          if pi_ig_items(i).item_name like pi_split_value escape '!'
            then
              l_created_idx_count := l_created_idx_count + 1;
              l_return.extend;
              l_return(l_created_idx_count) := pi_ig_items(i);
          end if;
        end loop;
      end if;

    return l_return;
  end split_logger_parameter;

  function split_logger_parameter(pi_tabform_items in t_tabform_items, pi_split_value in varchar2)
  return t_tabform_items
  as
    l_count number;
    l_created_idx_count number;
    l_return t_tabform_items := t_tabform_items();
  begin
    l_count := 0;
    l_created_idx_count := 0;
    for rec in 1..pi_tabform_items.count
    loop
      if pi_tabform_items(rec).item_name like pi_split_value escape '!'
      then
        l_count := l_count + 1;
      end if;
    end loop;
     
    if l_count > 0
      then
        for i in 1..pi_tabform_items.count
        loop
          if pi_tabform_items(i).item_name like pi_split_value escape '!'
            then
              l_created_idx_count := l_created_idx_count + 1;
              l_return.extend;
              l_return(l_created_idx_count) := pi_tabform_items(i);
          end if;
        end loop;
      end if;

    return l_return;
  end split_logger_parameter;

  function add_to_collection(pi_dest_collection in t_items, pi_src_collection in t_items)
  return t_items
  as
    l_dest_count number;
    l_return t_items;
  begin
    l_return := pi_dest_collection;
    l_dest_count := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;

  function add_to_collection(pi_dest_collection in t_ig_items, pi_src_collection in t_ig_items)
  return t_ig_items
  as
    l_dest_count number;
    l_return t_ig_items;
  begin
    l_return := pi_dest_collection;
    l_dest_count := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;

  function add_to_collection(pi_dest_collection in t_tabform_items, pi_src_collection in t_tabform_items)
  return t_tabform_items
  as
    l_dest_count number;
    l_return t_tabform_items;
  begin
    l_return := pi_dest_collection;
    l_dest_count := pi_dest_collection.count;

    for i in 1..pi_src_collection.count
    loop
      l_return.extend;
      l_return(l_dest_count + i) := pi_src_collection(i);
    end loop;
    return l_return;
  end add_to_collection;

  function get_logger_parameter_script(pi_items in t_items default null,
                                       pi_ig_items in t_ig_items default null,
                                       pi_tabform_items in t_tabform_items default null,
                                       pi_load_save_or_delete in varchar2,
                                       pi_pk_item in varchar2 default null)
  return clob
  as
    l_items t_items := t_items();
    l_items_count number;

    l_ig_items t_ig_items := t_ig_items();
    l_ig_items_count number;

    l_tabform_items t_tabform_items := t_tabform_items();
    l_tabform_items_count number;
    l_return clob;
  begin
    begin
      l_items := pi_items;
      l_items_count := l_items.count;
      exception
        when others then
          l_items_count := 0;
    end;

    begin 
      l_ig_items := pi_ig_items;
      l_ig_items_count := l_ig_items.count;
      exception
        when others then
          l_ig_items_count := 0;
    end;

    begin 
      l_tabform_items := pi_tabform_items;
      l_tabform_items_count := l_tabform_items.count;
      exception
        when others then
          l_tabform_items_count := 0;
    end;

    case
      when l_items_count > 0
        then
          for i in 1..l_items_count
          loop
            l_return := l_return || replace_parameter(c_logger_append_param,pi_items(i).item_name) || c_cr;
          end loop;
      when l_ig_items_count > 0
        then
          for i in 1..l_ig_items_count
          loop
            l_return := l_return || replace_parameter(c_logger_append_param,pi_ig_items(i).item_name) || c_cr;
          end loop;
      when l_tabform_items_count > 0
        then
          for i in 1..l_tabform_items_count
          loop
            l_return := l_return || replace_parameter(c_logger_append_param,pi_tabform_items(i).item_name) || c_cr;
          end loop;
      else
        null;
    end case;
    return l_return;
  end get_logger_parameter_script;


  function swap_pk_item_on_top
    (
      pi_items in t_items,
      pi_pk_item in varchar2 default null
    )
  return t_items
  as
    l_pk_item t_item;
    l_swap_item t_item;
    l_loop_count number;
    l_return t_items;
  begin
    l_return := pi_items;

    if pi_pk_item is not null
      then
        if l_return(1).item_name = pi_pk_item
          then
            l_return := pi_items;
          else
            l_swap_item.item_name       := l_return(1).item_name;
            l_swap_item.display_as_code := l_return(1).display_as_code;
            l_swap_item.item_data_type  := l_return(1).item_data_type;
            l_swap_item.is_required     := l_return(1).is_required;
            l_swap_item.item_default    := l_return(1).item_default;
            l_swap_item.region_name     := l_return(1).region_name;
            l_swap_item.page_id         := l_return(1).page_id;

            for i in 1..l_return.count
            loop
              if l_return(i).item_name = pi_pk_item
              then
                l_loop_count := i;

                l_pk_item.item_name       := l_return(i).item_name;
                l_pk_item.display_as_code := l_return(i).display_as_code;
                l_pk_item.item_data_type  := l_return(i).item_data_type;
                l_pk_item.is_required     := l_return(i).is_required;
                l_pk_item.item_default    := l_return(i).item_default;
                l_pk_item.region_name     := l_return(i).region_name;
                l_pk_item.page_id         := l_return(i).page_id;
              end if;
            end loop;

            -- SET PK_ITEM TOP
            l_return(1).item_name       := l_pk_item.item_name;
            l_return(1).display_as_code := l_pk_item.display_as_code;
            l_return(1).item_data_type  := l_pk_item.item_data_type;
            l_return(1).is_required     := l_pk_item.is_required;
            l_return(1).item_default    := l_pk_item.item_default;
            l_return(1).region_name     := l_pk_item.region_name;
            l_return(1).page_id         := l_pk_item.page_id;

            -- SET SWAP ITEM AT LOOP_COUNT
            l_return(l_loop_count).item_name       := l_swap_item.item_name;
            l_return(l_loop_count).display_as_code := l_swap_item.display_as_code;
            l_return(l_loop_count).item_data_type  := l_swap_item.item_data_type;
            l_return(l_loop_count).is_required     := l_swap_item.is_required;
            l_return(l_loop_count).item_default    := l_swap_item.item_default;
            l_return(l_loop_count).region_name     := l_swap_item.region_name;
            l_return(l_loop_count).page_id         := l_swap_item.page_id;

        end if;
      end if;
    return l_return;
  end swap_pk_item_on_top;

  function swap_pk_column_on_top
    (
      pi_ig_items in t_ig_items,
      pi_pk_column in varchar2 default null
    )
  return t_ig_items
  as
    l_pk_item t_ig_item;
    l_swap_item t_ig_item;
    l_loop_count number;
    l_return t_ig_items;
  begin
    l_return := pi_ig_items;

    if pi_pk_column is not null
      then
        if l_return(1).item_name = pi_pk_column
          then
            null;
          else
            l_swap_item.item_name               := l_return(1).item_name;
            l_swap_item.region_name             := l_return(1).region_name;
            l_swap_item.region_source_type_code := l_return(1).region_source_type_code;
            l_swap_item.edit_operations         := l_return(1).edit_operations;
            l_swap_item.is_editable             := l_return(1).is_editable;
            l_swap_item.item_data_type          := l_return(1).item_data_type;
            l_swap_item.source_expression       := l_return(1).source_expression;
            l_swap_item.db_column               := l_return(1).db_column;
            --no page id because the parameter would be the column name and the assigned is :COL_NAME

            for i in 1..l_return.count
            loop
              if l_return(i).item_name = pi_pk_column
              then
                l_loop_count := i;

                l_pk_item.item_name               := l_return(i).item_name;
                l_pk_item.region_name             := l_return(i).region_name;
                l_pk_item.region_source_type_code := l_return(i).region_source_type_code;
                l_pk_item.edit_operations         := l_return(i).edit_operations;
                l_pk_item.is_editable             := l_return(i).is_editable;
                l_pk_item.item_data_type          := l_return(i).item_data_type;
                l_pk_item.source_expression       := l_return(i).source_expression;
                l_pk_item.db_column               := l_return(i).db_column;                

              end if;
            end loop;

            -- SET PK_ITEM TOP
            l_return(1).item_name               := l_pk_item.item_name;
            l_return(1).region_name             := l_pk_item.region_name;
            l_return(1).region_source_type_code := l_pk_item.region_source_type_code;
            l_return(1).edit_operations         := l_pk_item.edit_operations;
            l_return(1).is_editable             := l_pk_item.is_editable;
            l_return(1).item_data_type          := l_pk_item.item_data_type;
            l_return(1).source_expression       := l_pk_item.source_expression;
            l_return(1).db_column               := l_pk_item.db_column;

            -- SET SWAP ITEM AT LOOP_COUNT
            l_return(l_loop_count).item_name               := l_swap_item.item_name;
            l_return(l_loop_count).region_name             := l_swap_item.region_name;
            l_return(l_loop_count).region_source_type_code := l_swap_item.region_source_type_code;
            l_return(l_loop_count).edit_operations         := l_swap_item.edit_operations;
            l_return(l_loop_count).is_editable             := l_swap_item.is_editable;
            l_return(l_loop_count).item_data_type          := l_swap_item.item_data_type;
            l_return(l_loop_count).source_expression       := l_swap_item.source_expression;
            l_return(l_loop_count).db_column               := l_swap_item.db_column;

        end if;
      end if;
    return l_return;
  end swap_pk_column_on_top;

  function swap_pk_column_on_top
    (
      pi_tabform_items in t_tabform_items,
      pi_pk_column in varchar2 default null
    )
  return t_tabform_items
  as
    l_pk_item t_tabform_item;
    l_swap_item t_tabform_item;
    l_loop_count number;
    l_return t_tabform_items;
  begin
    l_return := pi_tabform_items;

    if pi_pk_column is not null
      then
        if l_return(1).item_name = pi_pk_column
          then
            null;
          else
            l_swap_item.item_name         := l_return(1).item_name;
            l_swap_item.display_as_code   := l_return(1).display_as_code;
            l_swap_item.region_name       := l_return(1).region_name;
            l_swap_item.source_type_code  := l_return(1).source_type_code;
            --no page id because the parameter would be the column name and the assigned is :COL_NAME

            for i in 1..l_return.count
            loop
              if l_return(i).item_name = pi_pk_column
              then
                l_loop_count := i;

                l_pk_item.item_name         := l_return(i).item_name;
                l_pk_item.display_as_code   := l_return(i).display_as_code;
                l_pk_item.region_name       := l_return(i).region_name;
                l_pk_item.source_type_code  := l_return(i).source_type_code;               

              end if;
            end loop;

            -- SET PK_ITEM TOP
            l_return(1).item_name           := l_pk_item.item_name;
            l_return(1).display_as_code     := l_pk_item.display_as_code;
            l_return(1).region_name         := l_pk_item.region_name;
            l_return(1).source_type_code    := l_pk_item.source_type_code;


            -- SET SWAP ITEM AT LOOP_COUNT
            l_return(l_loop_count).item_name         := l_swap_item.item_name;
            l_return(l_loop_count).display_as_code   := l_swap_item.display_as_code;
            l_return(l_loop_count).region_name       := l_swap_item.region_name;
            l_return(l_loop_count).source_type_code  := l_swap_item.source_type_code;

        end if;
      end if;
    return l_return;
  end swap_pk_column_on_top;

  function get_procedure_body(pi_logger in number)
  return clob
  as
    l_return clob;
  begin
    if pi_logger = 0
      then l_return := c_procecure_body_script;
      else l_return := c_procecure_body_logger_script;
    end if; 
    return l_return;
  end get_procedure_body;

/* get_page_items
*  @pi_app_id items from which application
*  @pi_page_id items from which page in the defined application
*  @pi_region_name filter by region name
*
*  Description:
*  Returns the items values needed for further processing 
*/
  function get_page_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_region_name in varchar2 default null
    )
  return t_items
  as
    l_return t_items; 
  begin
    select aapi.item_name,
          aapi.display_as_code,
          case when upper(aapi.item_data_type) = 'VARCHAR'
            then 'VARCHAR2'
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
      on aapr.region_id = aapi.region_id
    where aapr.application_id = pi_app_id
      and aapr.page_id = pi_page_id
      and aapr.region_name = coalesce(pi_region_name,aapr.region_name)
    order by aapi.display_sequence,
             aapr.region_name
      ;
    
    return l_return;
  end get_page_items;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
    function get_ig_items
      (
        pi_app_id in number,
        pi_page_id in number,
        pi_region_name in varchar2 default null
      )
    return t_ig_items
    as
      l_return t_ig_items;
    begin
      select apic.name,
            aaig.Region_name,
            aapr.source_type_code, --(NATIVE_IG) 
            aaig.edit_operations, --(i:u:d) 
            aaig.is_editable, -- (Yes)
            case
              when apic.name = 'ROWID'
                  then 'NUMBER'
              else apic.Data_type
            end data_type, 
            apic.source_expression,
            apic.source_type_code --(DB_COLUMN)
      bulk collect into l_return
      from APEX_APPL_PAGE_IGS aaig
      join APEX_APPLICATION_PAGE_REGIONS aapr
        on aapr.region_id = aaig.region_id
      join APEX_APPL_PAGE_IG_COLUMNS apic
        on apic.region_id = aapr.region_id
      where aaig.application_id = pi_app_id
      and aaig.page_id = pi_page_id
      and aaig.region_name = coalesce(pi_region_name,aaig.region_name)
      and apic.source_type_code = 'DB_COLUMN'
    order by aapr.display_sequence,
              aapr.region_name
        ;

      return l_return;
    end get_ig_items;
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
    function get_tabform_items
      (
        pi_app_id in number,
        pi_page_id in number,
        pi_region_name in varchar2 default null
      )
    return t_tabform_items
    as
      l_return t_tabform_items;
    begin
      select aprc.COLUMN_ALIAS as item_name, 
             aprc.display_as_code,
             aapr.region_name,
             aapr.source_type_plugin_name as  source_type_code
      bulk collect into l_return
        from APEX_APPLICATION_PAGE_REGIONS aapr
        join APEX_APPLICATION_PAGE_RPT_COLS aprc
          on aprc.region_id = aapr.region_id
       where  aprc.application_id = pi_app_id
         and aprc.page_id = pi_page_id
         and aprc.region_name = coalesce(pi_region_name,aprc.region_name)
         and aprc.COLUMN_ALIAS not like 'CHECK$%'
    order by aprc.display_sequence,
             aapr.region_name
       ;
      return l_return;
    end get_tabform_items;
$end



  function get_regions
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_region_name in varchar2 default null
    )
  return t_regions
  as
    l_return t_regions;
  begin
$IF PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $THEN
    select aapr.region_name,
           aapr.source_type_code
     bulk collect into l_return
     from APEX_APPLICATION_PAGE_REGIONS aapr
     where aapr.application_id = pi_app_id
     and aapr.page_id = pi_page_id
     and aapr.region_name = coalesce(pi_region_name,aapr.region_name)
     order by aapr.display_sequence,
             aapr.region_name
     ;
$END
$IF PKG_APEX_VERSION.c_apex_version_5_0
  $THEN
     select aapr.region_name,
            aapr.source_type_plugin_name
      bulk collect into l_return
      from APEX_APPLICATION_PAGE_REGIONS aapr
      where aapr.application_id = pi_app_id
      and aapr.page_id = pi_page_id
      and aapr.region_name = coalesce(pi_region_name,aapr.region_name)
      order by aapr.display_sequence,
              aapr.region_name
      ;
$END
    return l_return;
  end get_regions;

  function get_ig_regions(pi_regions in t_regions)
  return t_regions
  as
    l_extend_count number := 0;
    l_return t_regions := t_regions();
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

  function get_tabform_regions(pi_regions in t_regions)
  return t_regions
  as
    l_extend_count number := 0;
    l_return t_regions := t_regions();
  begin
    for i in 1..pi_regions.count
    loop
      if pi_regions(i).source_type_code = 'NATIVE_TABFORM'
        then
          l_return.extend;
          l_extend_count := l_extend_count + 1;
          l_return(l_extend_count) := pi_regions(i);
      end if;
    end loop;

    return l_return;
  end get_tabform_regions;

  function get_logger_entries_script
  (
    pi_items in t_items default null,
    pi_ig_items in t_ig_items default null,
    pi_tabform_items in t_tabform_items default null,
    pi_source_script in clob,
    pi_load_save_or_delete in varchar2,
    pi_pk_item in varchar2 default null
  )
  return clob
  as 
    l_logger_pi_prm t_items;
    l_logger_po_prm t_items;
    l_logger_pio_prm t_items;
    l_logger_pi_pio_prm t_items := t_items();
    l_logger_po_pio_prm t_items := t_items();
    l_logger_prm t_items;

    l_logger_ig_pi_prm  t_ig_items;
    l_logger_ig_po_prm  t_ig_items;
    l_logger_ig_pio_prm t_ig_items;
    l_logger_ig_pi_pio_prm t_ig_items := t_ig_items();
    l_logger_ig_po_pio_prm t_ig_items := t_ig_items();
    l_logger_ig_prm t_ig_items;

    l_logger_tabform_pi_prm  t_tabform_items;
    l_logger_tabform_po_prm  t_tabform_items;
    l_logger_tabform_pio_prm t_tabform_items;
    l_logger_tabform_pi_pio_prm t_tabform_items := t_tabform_items();
    l_logger_tabform_po_pio_prm t_tabform_items := t_tabform_items();
    l_logger_tabform_prm t_tabform_items;

    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm_script clob;       
    
    l_return clob;

  begin 
    case 
      when pi_items is not null and pi_items.count > 0
        then
          l_logger_prm := get_logger_parameter(pi_items => pi_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

          l_logger_pi_prm := split_logger_parameter(pi_items => l_logger_prm, pi_split_value => 'PI!_%'); 

          l_logger_po_prm :=  split_logger_parameter(pi_items => l_logger_prm, pi_split_value => 'PO!_%');

          l_logger_pio_prm :=  split_logger_parameter(pi_items => l_logger_prm, pi_split_value => 'PIO!_%');


          l_logger_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_pi_pio_prm, pi_src_collection => l_logger_pi_prm);
          l_logger_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_pi_pio_prm, pi_src_collection => l_logger_pio_prm);

          l_logger_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_po_pio_prm, pi_src_collection => l_logger_pio_prm);
          l_logger_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_po_pio_prm, pi_src_collection => l_logger_po_prm);

          l_logger_pi_pio_prm_script := get_logger_parameter_script(pi_items => l_logger_pi_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);
          l_logger_po_pio_prm_script := get_logger_parameter_script(pi_items => l_logger_po_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

          l_return := replace_pi_pio(pi_source_script => pi_source_script, pi_logger_parameter => l_logger_pi_pio_prm_script);
          l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => l_logger_po_pio_prm_script);

      when pi_ig_items is not null and pi_ig_items.count > 0
        then
          l_logger_ig_prm := get_logger_parameter(pi_ig_items => pi_ig_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item); --TODO

          l_logger_ig_pi_prm := split_logger_parameter(pi_ig_items => l_logger_ig_prm, pi_split_value => 'PI!_%'); 

          l_logger_ig_po_prm :=  split_logger_parameter(pi_ig_items => l_logger_ig_prm, pi_split_value => 'PO!_%');

          l_logger_ig_pio_prm :=  split_logger_parameter(pi_ig_items => l_logger_ig_prm, pi_split_value => 'PIO!_%');


          l_logger_ig_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_ig_pi_pio_prm, pi_src_collection => l_logger_ig_pi_prm);
          l_logger_ig_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_ig_pi_pio_prm, pi_src_collection => l_logger_ig_pio_prm); 

          l_logger_ig_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_ig_po_pio_prm, pi_src_collection => l_logger_ig_pio_prm); 
          l_logger_ig_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_ig_po_pio_prm, pi_src_collection => l_logger_ig_po_prm);

          l_logger_pi_pio_prm_script := get_logger_parameter_script(pi_ig_items => l_logger_ig_pi_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item); 
          l_logger_po_pio_prm_script := get_logger_parameter_script(pi_ig_items => l_logger_ig_po_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

          l_return := replace_pi_pio(pi_source_script => pi_source_script, pi_logger_parameter => l_logger_pi_pio_prm_script);
          l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => l_logger_po_pio_prm_script);

       when pi_tabform_items is not null and pi_tabform_items.count > 0
        then
          l_logger_tabform_prm := get_logger_parameter(pi_tabform_items => pi_tabform_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

          l_logger_tabform_pi_prm := split_logger_parameter(pi_tabform_items => l_logger_tabform_prm, pi_split_value => 'PI!_%'); 

          l_logger_tabform_po_prm :=  split_logger_parameter(pi_tabform_items => l_logger_tabform_prm, pi_split_value => 'PO!_%');

          l_logger_tabform_pio_prm :=  split_logger_parameter(pi_tabform_items => l_logger_tabform_prm, pi_split_value => 'PIO!_%');


          l_logger_tabform_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_tabform_pi_pio_prm, pi_src_collection => l_logger_tabform_pi_prm);
          l_logger_tabform_pi_pio_prm := add_to_collection(pi_dest_collection => l_logger_tabform_pi_pio_prm, pi_src_collection => l_logger_tabform_pio_prm);

          l_logger_tabform_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_tabform_po_pio_prm, pi_src_collection => l_logger_tabform_pio_prm);
          l_logger_tabform_po_pio_prm := add_to_collection(pi_dest_collection => l_logger_tabform_po_pio_prm, pi_src_collection => l_logger_tabform_po_prm);

          l_logger_pi_pio_prm_script := get_logger_parameter_script(pi_tabform_items => l_logger_tabform_pi_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);
          l_logger_po_pio_prm_script := get_logger_parameter_script(pi_tabform_items => l_logger_tabform_po_pio_prm, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

          l_return := replace_pi_pio(pi_source_script => pi_source_script, pi_logger_parameter => l_logger_pi_pio_prm_script);
          l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => l_logger_po_pio_prm_script);

        else 
          null;
      end case;

    return l_return;
  end get_logger_entries_script;



  function get_save_proc_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0
    )
  return clob
  as    
    l_items t_items;
    l_save_script clob;

    l_logger_pi_prm t_items;
    l_logger_po_prm t_items;
    l_logger_pio_prm t_items;

    l_logger_pi_pio_prm t_items := t_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_items := t_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_items := get_page_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_items := swap_pk_item_on_top(pi_items => l_items, pi_pk_item => pi_pk_item);

    l_parameter_script := get_parameter_script(pi_items => l_items, pi_load_save_or_delete => 'S', pi_pk_item => pi_pk_item);
    
    case
      when pi_spec_or_body = 'S'
        then l_save_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_save_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_save_script, pi_procedure_name => c_save_proc_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_items => l_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'S',
                                              pi_pk_item => pi_pk_item
                                            );
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_save_proc_by_apex_items;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
  function get_ig_save_proc_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name in varchar2 default null
    )
  return clob
  as    
    l_ig_items t_ig_items;
    l_save_script clob;

    l_logger_pi_prm t_ig_items;
    l_logger_po_prm t_ig_items;
    l_logger_pio_prm t_ig_items;

    l_logger_pi_pio_prm t_ig_items := t_ig_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_ig_items := t_ig_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_ig_items := get_ig_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_ig_items := swap_pk_column_on_top(pi_ig_items => l_ig_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_ig_items => l_ig_items, pi_load_save_or_delete => 'S', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_save_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_save_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_save_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_ig_items => l_ig_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'S',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_ig_save_proc_by_apex_items;
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
  function get_tab_sav_proc_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name in varchar2 default null
    )
  return clob
  as    
    l_tabform_items t_tabform_items;
    l_save_script clob;

    l_logger_pi_prm t_tabform_items;
    l_logger_po_prm t_tabform_items;
    l_logger_pio_prm t_tabform_items;

    l_logger_pi_pio_prm t_tabform_items := t_tabform_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_tabform_items := t_tabform_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_tabform_items := get_tabform_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_tabform_items := swap_pk_column_on_top(pi_tabform_items => l_tabform_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_tabform_items => l_tabform_items, pi_load_save_or_delete => 'S', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_save_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_save_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_save_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_tabform_items => l_tabform_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'S',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_tab_sav_proc_by_apex_items;
$end

  function get_load_details_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0
    )
  return clob
  as    
    l_items t_items; 

    l_logger_pi_prm t_items;
    l_logger_po_prm t_items;
    l_logger_pio_prm t_items;

    l_logger_pi_pio_prm t_items := t_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_items := t_items();
    l_logger_po_pio_prm_script clob;

    l_load_detail_script clob; 
    l_parameter_script clob;     
    l_return clob;
  begin
    l_items := get_page_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_items := swap_pk_item_on_top(pi_items => l_items, pi_pk_item => pi_pk_item);

    l_parameter_script := get_parameter_script(pi_items => l_items, pi_load_save_or_delete => 'L', pi_pk_item => pi_pk_item);

    case
      when pi_spec_or_body = 'S'
        then l_load_detail_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then  l_load_detail_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_load_detail_script, pi_procedure_name => c_load_details_proc_name );
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_items => l_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'L',
                                              pi_pk_item => pi_pk_item
                                            );
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;

    return l_return;
    
  end get_load_details_by_apex_items;

  function get_update_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0
    )
  return clob
  as
    l_items t_items;

    l_logger_pi_prm t_items;
    l_logger_po_prm t_items;
    l_logger_pio_prm t_items;

    l_logger_pi_pio_prm t_items := t_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_items := t_items();
    l_logger_po_pio_prm_script clob;

    l_update_script clob; 
    l_parameter_script clob;   
    l_return clob;
  begin
    l_items := get_page_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_items := swap_pk_item_on_top(pi_items => l_items, pi_pk_item => pi_pk_item);

    l_parameter_script := get_parameter_script(pi_items => l_items,pi_load_save_or_delete => 'U', pi_pk_item => pi_pk_item);

    case
      when pi_spec_or_body = 'S'
        then l_update_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_update_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_update_script, pi_procedure_name => c_update_proc_name );
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_items => l_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'U',
                                              pi_pk_item => pi_pk_item
                                            );
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;

    return l_return;
  end get_update_by_apex_items;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
  function get_ig_update_by_apex_items 
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name varchar2 default null
    )
  return clob
  as    
    l_ig_items t_ig_items;
    l_update_script clob;

    l_logger_pi_prm t_ig_items;
    l_logger_po_prm t_ig_items;
    l_logger_pio_prm t_ig_items;

    l_logger_pi_pio_prm t_ig_items := t_ig_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_ig_items := t_ig_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_ig_items := get_ig_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_ig_items := swap_pk_column_on_top(pi_ig_items => l_ig_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_ig_items => l_ig_items, pi_load_save_or_delete => 'U', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_update_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_update_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_update_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_ig_items => l_ig_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'U',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_ig_update_by_apex_items;
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
  function get_tab_update_by_apex_items 
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name varchar2 default null
    )
  return clob
  as    
    l_tabform_items t_tabform_items;
    l_update_script clob;

    l_logger_pi_prm t_tabform_items;
    l_logger_po_prm t_tabform_items;
    l_logger_pio_prm t_tabform_items;

    l_logger_pi_pio_prm t_tabform_items := t_tabform_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_tabform_items := t_tabform_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_tabform_items := get_tabform_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_tabform_items := swap_pk_column_on_top(pi_tabform_items => l_tabform_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_tabform_items => l_tabform_items, pi_load_save_or_delete => 'U', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_update_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_update_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_update_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_tabform_items => l_tabform_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'U',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_tab_update_by_apex_items;
$end

  function get_delete_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0
    )
  return clob
  as
    l_items t_items;

    l_logger_pi_prm t_items;
    l_logger_po_prm t_items;
    l_logger_pio_prm t_items;

    l_logger_pi_pio_prm t_items := t_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_items := t_items();
    l_logger_po_pio_prm_script clob;

    l_delete_script clob; 
    l_parameter_script clob;   
    l_return clob;
  begin
    l_items := get_page_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_items := swap_pk_item_on_top(pi_items => l_items, pi_pk_item => pi_pk_item);

    l_parameter_script := get_parameter_script(pi_items => l_items,pi_load_save_or_delete => 'D', pi_pk_item => pi_pk_item);

    case
      when pi_spec_or_body = 'S'
        then l_delete_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_delete_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_delete_script, pi_procedure_name => c_delete_proc_name );
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_items => l_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'D',
                                              pi_pk_item => pi_pk_item
                                            );
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;

    return l_return;
  end get_delete_by_apex_items;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
  function get_ig_delete_by_apex_items 
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name varchar2 default null
    )
  return clob
  as    
    l_ig_items t_ig_items;
    l_delete_script clob;

    l_logger_pi_prm t_ig_items;
    l_logger_po_prm t_ig_items;
    l_logger_pio_prm t_ig_items;

    l_logger_pi_pio_prm t_ig_items := t_ig_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_ig_items := t_ig_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_ig_items := get_ig_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_ig_items := swap_pk_column_on_top(pi_ig_items => l_ig_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_ig_items => l_ig_items, pi_load_save_or_delete => 'D', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_delete_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_delete_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_delete_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_ig_items => l_ig_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'D',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_ig_delete_by_apex_items;
$end  

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
  function get_tab_delete_by_apex_items 
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_spec_or_body in varchar2,
      pi_region_name in varchar2,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_procedure_name varchar2 default null
    )
  return clob
  as    
    l_tabform_items t_tabform_items;
    l_delete_script clob;

    l_logger_pi_prm t_tabform_items;
    l_logger_po_prm t_tabform_items;
    l_logger_pio_prm t_tabform_items;

    l_logger_pi_pio_prm t_tabform_items := t_tabform_items();
    l_logger_pi_pio_prm_script clob;
    l_logger_po_pio_prm t_tabform_items := t_tabform_items();
    l_logger_po_pio_prm_script clob;

    l_parameter_script clob;   
    l_return clob;
  begin
    l_tabform_items := get_tabform_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);

    l_tabform_items := swap_pk_column_on_top(pi_tabform_items => l_tabform_items, pi_pk_column => pi_pk_column);

    l_parameter_script := get_parameter_script(pi_tabform_items => l_tabform_items, pi_load_save_or_delete => 'D', pi_pk_item => pi_pk_column); 
    
    case
      when pi_spec_or_body = 'S'
        then l_delete_script := c_procecure_spec_script;
      when pi_spec_or_body = 'B'
        then l_delete_script := get_procedure_body(pi_logger => pi_logger);
    end case;

    l_return := replace_procedure_name(pi_source_script => l_delete_script, pi_procedure_name => pi_procedure_name);
    l_return := replace_parameter(pi_source_script => l_return, pi_parameter => l_parameter_script);

    if pi_logger = 1 and pi_spec_or_body = 'B'
      then
        l_return := get_logger_entries_script(pi_tabform_items => l_tabform_items,
                                              pi_source_script => l_return,
                                              pi_load_save_or_delete => 'D',
                                              pi_pk_item => pi_pk_column
                                            );  
      else
        l_return := replace_pi_pio(pi_source_script => l_return, pi_logger_parameter => '');
        l_return := replace_po_pio(pi_source_script => l_return, pi_logger_parameter => '');
    end if;
 
    return l_return;
      
  end get_tab_delete_by_apex_items;
$end  

  --function get_load_list evtl?
/*
  -- in get_parameter in zufügen
  function get_update_by_apex_items
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null
    )
  return clob;  
*/
  function get_proc_and_func_spec_script
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null,
      pi_pk_column in varchar2 default null
    )
  return clob
  as
    l_regions t_regions;
    l_ig_regions t_regions;
    l_tabform_regions t_regions;
    l_tab_ig_prefix_proc_name varchar2(30);
    l_count_other_regions_as_ig number := 0;
    l_tab_ig_prefixes apex_application_global.vc_arr2;
    l_tab_ig_pk_cols apex_application_global.vc_arr2;
    l_pk_column varchar2(30);
    l_return clob;
  begin
    l_regions := get_regions(pi_app_id => pi_app_id,
                             pi_page_id => pi_page_id,
                             pi_region_name => pi_region_name
                            );

    for i in 1..l_regions.count
    loop
      if l_regions(i).source_type_code = 'NATIVE_IG' or  l_regions(i).source_type_code = 'NATIVE_TABFORM'
        then
          null;
        else
          l_count_other_regions_as_ig := l_count_other_regions_as_ig + 1;
      end if;
    end loop;

    if l_count_other_regions_as_ig > 0
      then
        l_return := get_save_proc_by_apex_items(pi_app_id => pi_app_id,
                                                pi_page_id => pi_page_id,
                                                pi_spec_or_body => 'S',
                                                pi_region_name => pi_region_name,
                                                pi_pk_item => pi_pk_item,
                                                pi_logger => pi_logger);

        l_return := l_return ||  get_load_details_by_apex_items(pi_app_id => pi_app_id,
                                                                pi_page_id => pi_page_id,
                                                                pi_spec_or_body => 'S',
                                                                pi_region_name => pi_region_name,
                                                                pi_pk_item => pi_pk_item,
                                                                pi_logger => pi_logger);

          l_return := l_return ||  get_update_by_apex_items(pi_app_id => pi_app_id,
                                                            pi_page_id => pi_page_id,
                                                            pi_spec_or_body => 'S',
                                                            pi_region_name => pi_region_name,
                                                            pi_pk_item => pi_pk_item,
                                                            pi_logger => pi_logger);                                                            

          l_return := l_return ||  get_delete_by_apex_items(pi_app_id => pi_app_id,
                                                            pi_page_id => pi_page_id,
                                                            pi_spec_or_body => 'S',
                                                            pi_region_name => pi_region_name,
                                                            pi_pk_item => pi_pk_item,
                                                            pi_logger => pi_logger); 
    end if;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
    l_ig_regions := get_ig_regions(pi_regions => l_regions);

    if l_ig_regions is not null and l_ig_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null and instr(pi_tab_ig_prefix_proc_name,',') > 0 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
          else
            l_tab_ig_prefixes(1) := pi_tab_ig_prefix_proc_name;
        end if;

        if pi_pk_column is not null and instr(pi_pk_column,':') > 0 
          then
            l_tab_ig_pk_cols := APEX_UTIL.STRING_TO_TABLE(p_string => pi_pk_column, p_separator => ':');
          else
            l_tab_ig_pk_cols(1) := pi_pk_column;
        end if;

        for i in 1..l_ig_regions.count
        loop
          if i <= l_tab_ig_prefixes.count  and l_tab_ig_prefixes(i) is not null 
            then
              l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; 
            else
              l_tab_ig_prefix_proc_name := 'IG_' || (i) || '_';
          end if;

          if i <= l_tab_ig_pk_cols.count and l_tab_ig_pk_cols(i) is not null
            then
              l_pk_column := l_tab_ig_pk_cols(i);
            else
              l_pk_column := 'ROWID';
          end if;

              
          l_return := l_return || get_ig_save_proc_by_apex_items(pi_app_id => pi_app_id,
                                                                 pi_page_id => pi_page_id,
                                                                 pi_spec_or_body => 'S',
                                                                 pi_region_name => l_ig_regions(i).region_name,
                                                                 pi_pk_column => l_pk_column,
                                                                 pi_logger => pi_logger,
                                                                 pi_procedure_name => l_tab_ig_prefix_proc_name || c_save_proc_name
                                                                 );

          l_return := l_return || get_ig_update_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'S',
                                                              pi_region_name => l_ig_regions(i).region_name,
                                                              pi_pk_column => l_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_update_proc_name
                                                              );
          
          l_return := l_return || get_ig_delete_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'S',
                                                              pi_region_name => l_ig_regions(i).region_name,
                                                              pi_pk_column => l_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_delete_proc_name
                                                              );
          
        end loop;
    end if;  
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
    l_tabform_regions := get_tabform_regions(pi_regions => l_regions);

    if l_tabform_regions is not null and l_tabform_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
        end if;

        for i in 1..l_tabform_regions.count
        loop
          if pi_tab_ig_prefix_proc_name is not null
            then
              l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; --pi_tab_ig_prefix_proc_name || '_';
            else
              l_tab_ig_prefix_proc_name := 'TAB_' || (i) || '_';
          end if;
          l_return := l_return || get_tab_sav_proc_by_apex_items(pi_app_id => pi_app_id,
                                                                 pi_page_id => pi_page_id,
                                                                 pi_spec_or_body => 'S',
                                                                 pi_region_name => l_tabform_regions(i).region_name,
                                                                 pi_pk_column => pi_pk_column,
                                                                 pi_logger => pi_logger,
                                                                 pi_procedure_name => l_tab_ig_prefix_proc_name || c_save_proc_name
                                                                 );

          l_return := l_return || get_tab_update_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'S',
                                                              pi_region_name => l_tabform_regions(i).region_name,
                                                              pi_pk_column => pi_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_update_proc_name
                                                              );
          
          l_return := l_return || get_tab_delete_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'S',
                                                              pi_region_name => l_tabform_regions(i).region_name,
                                                              pi_pk_column => pi_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_delete_proc_name
                                                              );
          
        end loop;
    end if;  
$end                                                 

    return l_return;
  end get_proc_and_func_spec_script;

  function get_proc_and_func_body_script
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_logger in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null,
      pi_pk_column in varchar2 default null
    )
  return clob
  as
    l_regions t_regions;
    l_ig_regions t_regions;
    l_tabform_regions t_regions;
    l_tab_ig_prefix_proc_name varchar2(30);
    l_count_other_regions_as_ig number := 0;
    l_tab_ig_prefixes apex_application_global.vc_arr2;
    l_tab_ig_pk_cols apex_application_global.vc_arr2;
    l_pk_column varchar2(30);
    l_return clob;
  begin
    l_regions := get_regions(pi_app_id => pi_app_id,
                             pi_page_id => pi_page_id,
                             pi_region_name => pi_region_name
                            );
    

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
        l_return :=  get_save_proc_by_apex_items(pi_app_id => pi_app_id,
                                                pi_page_id => pi_page_id,
                                                pi_spec_or_body => 'B',
                                                pi_region_name => pi_region_name,
                                                pi_pk_item => pi_pk_item,
                                                pi_logger => pi_logger);


        l_return := l_return ||  get_load_details_by_apex_items(pi_app_id => pi_app_id,
                                                                pi_page_id => pi_page_id,
                                                                pi_spec_or_body => 'B',
                                                                pi_region_name => pi_region_name,
                                                                pi_pk_item => pi_pk_item,
                                                                pi_logger => pi_logger);  

        l_return := l_return ||  get_update_by_apex_items(pi_app_id => pi_app_id,
                                                          pi_page_id => pi_page_id,
                                                          pi_spec_or_body => 'B',
                                                          pi_region_name => pi_region_name,
                                                          pi_pk_item => pi_pk_item,
                                                          pi_logger => pi_logger);                                                         

        l_return := l_return ||  get_delete_by_apex_items(pi_app_id => pi_app_id,
                                                          pi_page_id => pi_page_id,
                                                          pi_spec_or_body => 'B',
                                                          pi_region_name => pi_region_name,
                                                          pi_pk_item => pi_pk_item,
                                                          pi_logger => pi_logger); 
    end if; 
-- TODO add Tabform
$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
    l_ig_regions := get_ig_regions(pi_regions => l_regions);

    if l_ig_regions is not null and l_ig_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null and instr(pi_tab_ig_prefix_proc_name,',') > 0 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
          else
            l_tab_ig_prefixes(1) := pi_tab_ig_prefix_proc_name;
        end if;

        if pi_pk_column is not null and instr(pi_pk_column,':') > 0
          then
            l_tab_ig_pk_cols := APEX_UTIL.STRING_TO_TABLE(p_string => pi_pk_column, p_separator => ':');
          else
            l_tab_ig_pk_cols(1) := pi_pk_column;
        end if;

        for i in 1..l_ig_regions.count
        loop
          if i <= l_tab_ig_prefixes.count  and l_tab_ig_prefixes(i) is not null --pi_tab_ig_prefix_proc_name is not null
            then
              l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; --pi_tab_ig_prefix_proc_name || '_';
            else
              l_tab_ig_prefix_proc_name := 'IG_' || (i) || '_';
          end if;

          if i <= l_tab_ig_pk_cols.count and l_tab_ig_pk_cols(i) is not null
            then
              l_pk_column := l_tab_ig_pk_cols(i);
            else
              l_pk_column := 'ROWID';
          end if;
          l_return := l_return || get_ig_save_proc_by_apex_items(pi_app_id => pi_app_id,
                                                                 pi_page_id => pi_page_id,
                                                                 pi_spec_or_body => 'B',
                                                                 pi_region_name => l_ig_regions(i).region_name,
                                                                 pi_pk_column => l_pk_column,
                                                                 pi_logger => pi_logger,
                                                                 pi_procedure_name => l_tab_ig_prefix_proc_name || c_save_proc_name
                                                                 );

          l_return := l_return || get_ig_update_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'B',
                                                              pi_region_name => l_ig_regions(i).region_name,
                                                              pi_pk_column => l_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_update_proc_name
                                                              );
          
          l_return := l_return || get_ig_delete_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'B',
                                                              pi_region_name => l_ig_regions(i).region_name,
                                                              pi_pk_column => l_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_delete_proc_name
                                                              );
          
        end loop;
    end if;
$end       
$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
    l_tabform_regions := get_tabform_regions(pi_regions => l_regions);

    if l_tabform_regions is not null and l_tabform_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
        end if;

        for i in 1..l_tabform_regions.count
        loop
          if pi_tab_ig_prefix_proc_name is not null
            then
              l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; --pi_tab_ig_prefix_proc_name || '_';
            else
              l_tab_ig_prefix_proc_name := 'TAB_' || (i) || '_';
          end if;
          l_return := l_return || get_tab_sav_proc_by_apex_items(pi_app_id => pi_app_id,
                                                                 pi_page_id => pi_page_id,
                                                                 pi_spec_or_body => 'B',
                                                                 pi_region_name => l_tabform_regions(i).region_name,
                                                                 pi_pk_column => pi_pk_column,
                                                                 pi_logger => pi_logger,
                                                                 pi_procedure_name => l_tab_ig_prefix_proc_name || c_save_proc_name
                                                                 );

          l_return := l_return || get_tab_update_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'B',
                                                              pi_region_name => l_tabform_regions(i).region_name,
                                                              pi_pk_column => pi_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_update_proc_name
                                                              );
          
          l_return := l_return || get_tab_delete_by_apex_items(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,
                                                              pi_spec_or_body => 'B',
                                                              pi_region_name => l_tabform_regions(i).region_name,
                                                              pi_pk_column => pi_pk_column,
                                                              pi_logger => pi_logger,
                                                              pi_procedure_name => l_tab_ig_prefix_proc_name || c_delete_proc_name
                                                              );
          
        end loop;
    end if;  
$end              
    return l_return;
  end get_proc_and_func_body_script;

  function get_pkg_spec
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_pkg_name varchar(30);
    l_pkg_spec clob;
    l_func_and_proc clob;
    l_return clob;
  begin
    l_pkg_name := get_pkg_name(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_pkg_name => pi_pkg_name);

    l_func_and_proc := get_proc_and_func_spec_script(pi_app_id => pi_app_id,
                                                     pi_page_id => pi_page_id,
                                                     pi_region_name => pi_region_name,
                                                     pi_pk_item => pi_pk_item,
                                                     pi_pk_column => pi_pk_column,
                                                     pi_tab_ig_prefix_proc_name => pi_tab_ig_prefix_proc_name
                                                     );

    l_pkg_spec := replace_pkg_name(pi_source_script => c_pkg_spec_script, pi_pkg_name => l_pkg_name);

    l_return := replace_func_proc(pi_source_script => l_pkg_spec, pi_func_proc => l_func_and_proc);

    return l_return;  
  end get_pkg_spec;

  function get_pkg_body
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_pkg_name varchar(30);
    l_pkg_body clob;
    l_func_and_proc clob;
    l_return clob;
  begin
    l_pkg_name := get_pkg_name(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_pkg_name => pi_pkg_name);

    l_func_and_proc := get_proc_and_func_body_script(pi_app_id => pi_app_id,
                                                     pi_page_id => pi_page_id,
                                                     pi_region_name => pi_region_name,
                                                     pi_pk_item => pi_pk_item,
                                                     pi_pk_column => pi_pk_column,
                                                     pi_logger => pi_logger,
                                                     pi_tab_ig_prefix_proc_name => pi_tab_ig_prefix_proc_name);

    if pi_logger = 0
      then
        l_pkg_body := replace_pkg_name(pi_source_script => c_pkg_body_script, pi_pkg_name => l_pkg_name);
      else
        l_pkg_body := replace_pkg_name(pi_source_script => c_pkg_body_with_logger_script, pi_pkg_name => l_pkg_name);
    end if;

    l_return := replace_func_proc(pi_source_script => l_pkg_body, pi_func_proc => l_func_and_proc);

    return l_return;  
  end get_pkg_body;  

  function get_apex_call_script
  (
    pi_app_id in number,
    pi_page_id in number,    
    pi_load_save_or_delete in varchar2,
    pi_procedure_name in varchar2,
    pi_pkg_name in varchar2 default null,
    pi_region_name in varchar2 default null,
    pi_pk_item in varchar2 default null 
  )
return clob
as
  l_items t_items := t_items();
  l_apex_call_parameter_script clob;
  l_pkg_name varchar2(30);
 l_return clob;
begin

  l_pkg_name := get_pkg_name(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_pkg_name => pi_pkg_name);

  l_items := get_page_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);
  l_items := swap_pk_item_on_top(pi_items => l_items, pi_pk_item => pi_pk_item);

  l_apex_call_parameter_script := get_apex_call_parameter_script(pi_items => l_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => pi_pk_item);

  l_return := replace_pkg_name(pi_source_script => c_apex_call_script , pi_pkg_name => l_pkg_name);
  l_return := replace_procedure_name(pi_source_script => l_return, pi_procedure_name => pi_procedure_name);
  l_return := replace_func_proc(pi_source_script => l_return, pi_func_proc => l_apex_call_parameter_script);

return l_return;
end get_apex_call_script;

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
    function get_ig_apex_call_script
      (
        pi_app_id in number,
        pi_page_id in number,    
        pi_load_save_or_delete in varchar2,
        pi_procedure_name in varchar2,
        pi_pkg_name in varchar2 default null,
        pi_region_name in varchar2 default null,
        pi_pk_column in varchar2 default null 
      )
    return clob
    as
      l_ig_items t_ig_items := t_ig_items();
      l_apex_call_parameter_script clob;
      l_pk_column varchar2(30);
      l_pkg_name varchar2(30);
      l_return clob;
    begin
      if pi_pk_column is not null 
        then l_pk_column := pi_pk_column;
        else l_pk_column := 'ROWID';
      end if;
      l_pkg_name := get_pkg_name(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_pkg_name => pi_pkg_name);

      l_ig_items := get_ig_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);
      l_ig_items := swap_pk_column_on_top(pi_ig_items =>l_ig_items, pi_pk_column => l_pk_column);

      l_apex_call_parameter_script := get_apex_call_parameter_script(pi_ig_items => l_ig_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => l_pk_column);

      l_return := replace_pkg_name(pi_source_script => c_apex_call_script , pi_pkg_name => l_pkg_name);
      l_return := replace_procedure_name(pi_source_script => l_return, pi_procedure_name => pi_procedure_name);
      l_return := replace_func_proc(pi_source_script => l_return, pi_func_proc => l_apex_call_parameter_script);

    return l_return;
    end get_ig_apex_call_script;
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
    function get_tab_apex_call_script
      (
        pi_app_id in number,
        pi_page_id in number,    
        pi_load_save_or_delete in varchar2,
        pi_procedure_name in varchar2,
        pi_pkg_name in varchar2 default null,
        pi_region_name in varchar2 default null,
        pi_pk_column in varchar2 default null 
      )
    return clob
    as
      l_tabform_items t_tabform_items := t_tabform_items();
      l_apex_call_parameter_script clob;
      l_pk_column varchar2(30);
      l_pkg_name varchar2(30);
      l_return clob;
    begin

      l_pkg_name := get_pkg_name(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_pkg_name => pi_pkg_name);

      l_tabform_items := get_tabform_items(pi_app_id => pi_app_id, pi_page_id => pi_page_id, pi_region_name => pi_region_name);
      l_tabform_items := swap_pk_column_on_top(pi_tabform_items =>l_tabform_items, pi_pk_column => l_pk_column);

      l_apex_call_parameter_script := get_apex_call_parameter_script(pi_tabform_items => l_tabform_items, pi_load_save_or_delete => pi_load_save_or_delete, pi_pk_item => l_pk_column);

      l_return := replace_pkg_name(pi_source_script => c_apex_call_script , pi_pkg_name => l_pkg_name);
      l_return := replace_procedure_name(pi_source_script => l_return, pi_procedure_name => pi_procedure_name);
      l_return := replace_func_proc(pi_source_script => l_return, pi_func_proc => l_apex_call_parameter_script);

    return l_return;
    end get_tab_apex_call_script;
$end

  function get_save_proc_for_apex_proc
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_is_tab_or_ig in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_return clob;
  begin
    case pi_is_tab_or_ig  
      when 0
        then
          l_return := get_apex_call_script(pi_app_id => pi_app_id,
                                          pi_page_id => pi_page_id,    
                                          pi_load_save_or_delete => 'S',
                                          pi_procedure_name => c_save_proc_name,
                                          pi_pkg_name => pi_pkg_name,
                                          pi_region_name => pi_region_name,
                                          pi_pk_item => pi_pk_item 
                                        );
$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
      when 1
        then 
          l_return := get_ig_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'S',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_save_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              );  
$end 
$if PKG_APEX_VERSION.c_apex_version_5_0
  $then    
      when 3
        then 
          l_return := get_tab_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'S',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_save_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              ); 
$end
      else
        null;
    end case;                 
    return l_return;
  end get_save_proc_for_apex_proc;

  function get_load_d_proc_for_apex_proc
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null
    )
  return clob
  as
    l_return clob;
  begin
    l_return := get_apex_call_script(pi_app_id => pi_app_id,
                                     pi_page_id => pi_page_id,    
                                     pi_load_save_or_delete => 'L',
                                     pi_procedure_name => c_load_details_proc_name,
                                     pi_pkg_name => pi_pkg_name,
                                     pi_region_name => pi_region_name,
                                     pi_pk_item => pi_pk_item 
                                   );
    
    return l_return;
  end get_load_d_proc_for_apex_proc;

    function get_update_proc_for_apex_proc
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_is_tab_or_ig in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_return clob;
  begin
    case pi_is_tab_or_ig  
      when 0
        then
          l_return := get_apex_call_script(pi_app_id => pi_app_id,
                                          pi_page_id => pi_page_id,    
                                          pi_load_save_or_delete => 'U',
                                          pi_procedure_name => c_update_proc_name,
                                          pi_pkg_name => pi_pkg_name,
                                          pi_region_name => pi_region_name,
                                          pi_pk_item => pi_pk_item 
                                        );
$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then      
      when 1
        then 
          l_return := get_ig_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'U',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_update_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              ); 
$end
$if PKG_APEX_VERSION.c_apex_version_5_0
  $then    
      when 3
        then 
          l_return := get_tab_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'U',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_update_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              ); 
$end
      else
        null;
    end case;
    return l_return;
  end get_update_proc_for_apex_proc;

  function get_del_proc_for_apex_proc
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_is_tab_or_ig in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_items t_items;
    l_apex_call_parameter_script clob;
    l_pkg_name varchar2(30);
    l_return clob;
  begin
    case pi_is_tab_or_ig  
      when 0
        then
          l_return := get_apex_call_script(pi_app_id => pi_app_id,
                                          pi_page_id => pi_page_id,    
                                          pi_load_save_or_delete => 'D',
                                          pi_procedure_name => c_delete_proc_name,
                                          pi_pkg_name => pi_pkg_name,
                                          pi_region_name => pi_region_name,
                                          pi_pk_item => pi_pk_item 
                                        );
 
$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then    
      when 1
        then 
          l_return := get_ig_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'D',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_delete_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              ); 
$end

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then    
      when 3
        then 
          l_return := get_tab_apex_call_script(pi_app_id => pi_app_id,
                                              pi_page_id => pi_page_id,    
                                              pi_load_save_or_delete => 'D',
                                              pi_procedure_name => pi_tab_ig_prefix_proc_name || c_delete_proc_name,
                                              pi_pkg_name => pi_pkg_name,
                                              pi_region_name => pi_region_name,
                                              pi_pk_column => pi_pk_item
                                              ); 
$end
      else
        null;
    end case;

    return l_return;
  end get_del_proc_for_apex_proc;

-- =============================== IN APEX USED FUNCTIONS ===============================
  function check_has_tab_ig_on_page
    (
      pi_app_id in number,
      pi_page_id in number
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


/* ================================================= */
/* ================================================= */
/* ================================================= */
  function get_proc_all_calls_for_apex
    (
      pi_app_id in number,
      pi_page_id in number,      
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_tab_ig_prefix_proc_name in varchar2 default null --for the future to set it from outside
    )
  return clob
  as
    l_regions t_regions;
    l_ig_regions t_regions;
    l_tabform_regions t_regions;

    l_tab_ig_prefix_proc_name varchar2(30);
    l_tab_ig_prefixes apex_application_global.vc_arr2;
    l_tab_ig_pk_cols apex_application_global.vc_arr2;
    l_count_other_regions_as_ig number := 0;
    l_pk_column varchar2(30);

    l_save clob;
    l_update clob;
    l_delete clob;
    l_ig_tab_call_process clob;

    l_return clob;
  begin
    l_regions := get_regions(pi_app_id => pi_app_id,
                             pi_page_id => pi_page_id,
                             pi_region_name => pi_region_name
                            );

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
        l_return := get_save_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                pi_page_id => pi_page_id,    
                                                pi_pkg_name => upper(pi_pkg_name),
                                                pi_region_name => pi_region_name,
                                                pi_pk_item => pi_pk_item);

        l_return := l_return || get_load_d_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                              pi_page_id => pi_page_id,    
                                                              pi_pkg_name => upper(pi_pkg_name),
                                                              pi_region_name => pi_region_name,
                                                              pi_pk_item => pi_pk_item);

        l_return := l_return || get_update_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                          pi_page_id => pi_page_id,    
                                                          pi_pkg_name => upper(pi_pkg_name),
                                                          pi_region_name => pi_region_name,
                                                          pi_pk_item => pi_pk_item);  

        l_return := l_return || get_del_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                          pi_page_id => pi_page_id,    
                                                          pi_pkg_name => upper(pi_pkg_name),
                                                          pi_region_name => pi_region_name,
                                                          pi_pk_item => pi_pk_item);   
    end if;   

$if PKG_APEX_VERSION.c_apex_version_5_0
  $then
    l_tabform_regions := get_tabform_regions(pi_regions => l_regions);
    --TODO pi_tab_ig_prefix_proc_name, pi_pk_column pk coloumns can be more if we had 2 or more IG on page same for ig_prefix
    if l_tabform_regions is not null and l_tabform_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
        end if;

        for i in 1..l_tabform_regions.count
        loop
          if pi_tab_ig_prefix_proc_name is not null
            then
              l_tab_ig_prefix_proc_name := upper(l_tab_ig_prefixes(i)) || '_'; --pi_tab_ig_prefix_proc_name || '_';
            else
              l_tab_ig_prefix_proc_name := 'TAB_' || (i) || '_';
          end if;
          -- TODO get_ig_apex_call_proc
          
          l_save :=  get_save_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                    pi_page_id => pi_page_id,    
                                                    pi_pkg_name => upper(pi_pkg_name),
                                                    pi_region_name => l_tabform_regions(i).region_name,
                                                    pi_pk_item => pi_pk_column,
                                                    pi_is_tab_or_ig => 3,
                                                    pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);

          l_update :=  get_update_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                        pi_page_id => pi_page_id,    
                                                        pi_pkg_name => upper(pi_pkg_name),
                                                        pi_region_name => l_tabform_regions(i).region_name,
                                                        pi_pk_item => pi_pk_column,
                                                        pi_is_tab_or_ig => 3,
                                                        pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);
          
          l_delete :=  get_del_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                     pi_page_id => pi_page_id,    
                                                     pi_pkg_name => upper(pi_pkg_name),
                                                     pi_region_name => l_tabform_regions(i).region_name,
                                                     pi_pk_item => pi_pk_column,
                                                     pi_is_tab_or_ig => 3,
                                                     pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);                                              

          l_ig_tab_call_process := c_ig_tab_form_gen_call_script;

          l_ig_tab_call_process := replace_ig_tab_save_call(pi_source_script => l_ig_tab_call_process, pi_save_script => l_save);
          l_ig_tab_call_process := replace_ig_tab_update_call(pi_source_script => l_ig_tab_call_process, pi_update_script => l_update);
          l_ig_tab_call_process := replace_ig_tab_delete_call(pi_source_script => l_ig_tab_call_process, pi_delete_script => l_delete);

          l_return := l_return || l_ig_tab_call_process;
        
        end loop;
    end if;
$end      

$if PKG_APEX_VERSION.c_apex_version_5_1 or PKG_APEX_VERSION.c_apex_version_5_1_greater
  $then
    l_ig_regions := get_ig_regions(pi_regions => l_regions);
    --TODO pi_tab_ig_prefix_proc_name, pi_pk_column pk coloumns can be more if we had 2 or more IG on page same for ig_prefix
    if l_ig_regions is not null and l_ig_regions.count > 0
      then
        if pi_tab_ig_prefix_proc_name is not null and instr(pi_tab_ig_prefix_proc_name,',') > 0 
          then 
            l_tab_ig_prefixes := APEX_UTIL.STRING_TO_TABLE(p_string => pi_tab_ig_prefix_proc_name, p_separator => ',');
          else
            l_tab_ig_prefixes(1) := pi_tab_ig_prefix_proc_name;
        end if;

        if pi_pk_column is not null and instr(pi_pk_column,':') > 0 
          then
            l_tab_ig_pk_cols := APEX_UTIL.STRING_TO_TABLE(p_string => pi_pk_column, p_separator => ':');
          else
            l_tab_ig_pk_cols(1) := pi_pk_column;
        end if;

        for i in 1..l_ig_regions.count
        loop
          if i <= l_tab_ig_prefixes.count  and l_tab_ig_prefixes(i) is not null --pi_tab_ig_prefix_proc_name is not null
            then
              l_tab_ig_prefix_proc_name := l_tab_ig_prefixes(i) || '_'; --pi_tab_ig_prefix_proc_name || '_';
            else
              l_tab_ig_prefix_proc_name := 'IG_' || (i) || '_';
          end if;

          if i <= l_tab_ig_pk_cols.count and l_tab_ig_pk_cols(i) is not null
            then
              l_pk_column := l_tab_ig_pk_cols(i);
            else
              l_pk_column := 'ROWID';
          end if;
          
          l_save :=  get_save_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                    pi_page_id => pi_page_id,    
                                                    pi_pkg_name => upper(pi_pkg_name),
                                                    pi_region_name => l_ig_regions(i).region_name,
                                                    pi_pk_item => l_pk_column,
                                                    pi_is_tab_or_ig => 1,
                                                    pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);

          l_update :=  get_update_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                        pi_page_id => pi_page_id,    
                                                        pi_pkg_name => upper(pi_pkg_name),
                                                        pi_region_name => l_ig_regions(i).region_name,
                                                        pi_pk_item => l_pk_column,
                                                        pi_is_tab_or_ig => 1,
                                                        pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);
          
          l_delete :=  get_del_proc_for_apex_proc(pi_app_id => pi_app_id,
                                                     pi_page_id => pi_page_id,    
                                                     pi_pkg_name => upper(pi_pkg_name),
                                                     pi_region_name => l_ig_regions(i).region_name,
                                                     pi_pk_item => l_pk_column,
                                                     pi_is_tab_or_ig => 1,
                                                     pi_tab_ig_prefix_proc_name => l_tab_ig_prefix_proc_name);                                              

          l_ig_tab_call_process := c_ig_tab_form_gen_call_script;

          l_ig_tab_call_process := replace_ig_tab_save_call(pi_source_script => l_ig_tab_call_process, pi_save_script => l_save);
          l_ig_tab_call_process := replace_ig_tab_update_call(pi_source_script => l_ig_tab_call_process, pi_update_script => l_update);
          l_ig_tab_call_process := replace_ig_tab_delete_call(pi_source_script => l_ig_tab_call_process, pi_delete_script => l_delete);

          l_return := l_return || l_ig_tab_call_process;
        
        end loop;
    end if;
$end                                                                                  
                                                                               
    return l_return;
  end get_proc_all_calls_for_apex;

/* ================================================= */
/* ================================================= */
/* ================================================= */ 
  function get_page_api
    (
      pi_app_id in number,
      pi_page_id in number,
      pi_pkg_name in varchar2 default null,
      pi_region_name in varchar2 default null,
      pi_pk_item in varchar2 default null,
      pi_pk_column in varchar2 default null,
      pi_logger in number default 0,
      pi_tab_ig_prefix_proc_name in varchar2 default null
    )
  return clob
  as
    l_return clob;
  begin
    l_return := get_pkg_spec(pi_app_id => pi_app_id,
                             pi_page_id => pi_page_id,
                             pi_pkg_name => upper(pi_pkg_name),
                             pi_region_name => pi_region_name,
                             pi_pk_item => pi_pk_item,
                             pi_pk_column => pi_pk_column,
                             pi_tab_ig_prefix_proc_name => upper(pi_tab_ig_prefix_proc_name)
                            );

    l_return := l_return || get_pkg_body(pi_app_id => pi_app_id,
                                        pi_page_id => pi_page_id,
                                        pi_pkg_name => upper(pi_pkg_name),
                                        pi_region_name => pi_region_name,
                                        pi_pk_item => pi_pk_item,
                                        pi_pk_column => pi_pk_column,
                                        pi_logger => pi_logger, 
                                        pi_tab_ig_prefix_proc_name => upper(pi_tab_ig_prefix_proc_name)
                                       );
    return l_return;
  end get_page_api;

end api_by_apex_items;