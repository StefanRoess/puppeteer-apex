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
  subtype t_max_vc2 is varchar2(32767);

end pup_constants;