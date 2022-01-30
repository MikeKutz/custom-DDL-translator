-- run as owner
@ddlt_UDT_types.sql
@ddlt_util.pks
@ddlt_util.pkb
@ddlt_master_obj_spec.sql
@ddlt_master_obj_body.sql

-- RAS stuff
@ddlt_ras_const.pks
@ddlt_ras_json2code.pks
@ddlt_ras_json2code.pkb

@ddlt_ras_security_class_spec.sql
@ddlt_ras_security_class_body.sql
@ddlt_ras_acl_spec.sql
@ddlt_ras_acl_body.sql
@ddlt_ras_policy_spec.sql
@ddlt_ras_policy_body.sql

-- ut packages -- currently SQL file contains both
@test/ddlt_ras_ut.sql