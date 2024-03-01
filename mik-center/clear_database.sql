-- Quickly delete all tables to be able to restore a database dump
-- without having to look up the CREATE and GRANT commands

-- tables as per v. 3.6

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE authority;
DROP TABLE batch;
DROP TABLE batch_x_process;
DROP TABLE client;
DROP TABLE client_x_listcolumn;
DROP TABLE client_x_user;
DROP TABLE comment;
DROP TABLE dataeditor_setting;
DROP TABLE docket;
DROP TABLE filter;
DROP TABLE folder;
DROP TABLE importconfiguration;
DROP TABLE importconfiguration_x_mappingfile;
DROP TABLE ldapgroup;
DROP TABLE ldapserver;
DROP TABLE listcolumn;
DROP TABLE mappingfile;
DROP TABLE process;
DROP TABLE process_x_property;
DROP TABLE project;
DROP TABLE project_x_template;
DROP TABLE project_x_user;
DROP TABLE property;
DROP TABLE role;
DROP TABLE role_x_authority;
DROP TABLE ruleset;
DROP TABLE searchfield;
DROP TABLE task;
DROP TABLE task_x_role;
DROP TABLE template;
DROP TABLE template_x_property;
DROP TABLE urlparameter;
DROP TABLE user;
DROP TABLE user_x_role;
DROP TABLE workflow;
DROP TABLE workflowcondition;
DROP TABLE workpiece_x_property;
SET FOREIGN_KEY_CHECKS = 1;
