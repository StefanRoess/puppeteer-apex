create or replace package pup_constants
as
  --------------------
  -- global constants
  --------------------
  c_apex_version_5_0         constant boolean := false;
  c_apex_version_5_1         constant boolean := true;
  c_apex_version_5_1_greater constant boolean := false;

  -------------------
  -- global subtypes
  -------------------
  subtype t_small_vc2   is varchar2(10);
  subtype t_medium_vc2  is varchar2(100);
  subtype t_big_vc2     is varchar2(1000);
  subtype t_huge_vc2    is varchar2(4000);
  subtype t_max_vc2     is varchar2(32767);


  -- SUBTYPE char_small_t IS VARCHAR2 (100);
  -- SUBTYPE char_medium_t IS VARCHAR2 (1000);
  -- SUBTYPE char_big_t IS VARCHAR2 (4000);
  -- SUBTYPE char_huge_t IS VARCHAR2 (32767);

end pup_constants;