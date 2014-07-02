
--------------------------------------------------------
--  File created - Wednesday-July-02-2014   
--------------------------------------------------------

Insert into HIG_MODULES (HMO_MODULE,HMO_TITLE,HMO_FILENAME,HMO_MODULE_TYPE,HMO_FASTPATH_OPTS,HMO_FASTPATH_INVALID,HMO_USE_GRI,HMO_APPLICATION,HMO_MENU) values ('NTH0001','Northamptonshire Bus Stop XML Extract','test_report.rep_params','WEB',null,'N','N','MAI','FORM');

Insert into HIG_MODULE_ROLES (HMR_MODULE,HMR_ROLE,HMR_MODE) values ('NTH0001','HIG_ADMIN','NORMAL');
Insert into HIG_MODULE_ROLES (HMR_MODULE,HMR_ROLE,HMR_MODE) values ('NTH0001','HIG_USER','NORMAL');
Insert into HIG_MODULE_ROLES (HMR_MODULE,HMR_ROLE,HMR_MODE) values ('NTH0001','WEB_USER','NORMAL');

Insert into HIG_PROCESS_TYPES (HPT_PROCESS_TYPE_ID,HPT_NAME,HPT_DESCR,HPT_WHAT_TO_CALL,HPT_INITIATION_MODULE,HPT_INTERNAL_MODULE,HPT_INTERNAL_MODULE_PARAM,HPT_PROCESS_LIMIT,HPT_RESTARTABLE,HPT_SEE_IN_HIG2510,HPT_AREA_TYPE,HPT_POLLING_ENABLED,HPT_POLLING_FTP_TYPE_ID) values (61,'Bus Stop Assets XML Extract','This process will execute a bespoke process which will extract all ''TI'' asset types from the database and create an XML file from the data.','x_northants_xml.XMLDataExtract;',null,null,null,null,'N','Y',null,'Y',null);

Insert into HIG_MODULES (HMO_MODULE,HMO_TITLE,HMO_FILENAME,HMO_MODULE_TYPE,HMO_FASTPATH_OPTS,HMO_FASTPATH_INVALID,HMO_USE_GRI,HMO_APPLICATION,HMO_MENU) values ('NTH0001','Northamptonshire Bus Stop XML Extract','test_report.rep_params','WEB',null,'N','N','MAI','FORM');
Insert into GRI_MODULES (GRM_MODULE,GRM_MODULE_TYPE,GRM_MODULE_PATH,GRM_FILE_TYPE,GRM_TAG_FLAG,GRM_TAG_TABLE,GRM_TAG_COLUMN,GRM_TAG_WHERE,GRM_LINESIZE,GRM_PAGESIZE,GRM_PRE_PROCESS) values ('NTH0001','SVR','$PROD_HOME/bin','lis','N',null,null,null,132,66,null);