create or replace package PKG_APEX_VERSION
as
  c_apex_version_5_0         constant boolean := false;
  c_apex_version_5_1         constant boolean := true;
  c_apex_version_5_1_greater constant boolean := false;
end PKG_APEX_VERSION;