SET poc_database       = 'POC';
SET poc_owner_schema   = 'POC.poc_owner';
SET poc_warehouse      = 'poc_wh';
SET poc_owner_role     = 'poc_owner_role';

USE ROLE sysadmin;

CREATE OR REPLACE DATABASE IDENTIFIER ( $poc_database ) DATA_RETENTION_TIME_IN_DAYS = 7;

CREATE OR REPLACE WAREHOUSE IDENTIFIER ( $poc_warehouse ) WITH
WAREHOUSE_SIZE      = 'X-SMALL'
AUTO_SUSPEND        = 60
AUTO_RESUME         = TRUE
MIN_CLUSTER_COUNT   = 1
MAX_CLUSTER_COUNT   = 4
SCALING_POLICY      = 'STANDARD'
INITIALLY_SUSPENDED = TRUE;

If your POC involves Snowpark, you may want to add a WAREHOUSE_TYPE ='SNOWPARK-OPTIMIZED' to have a bigger memory allocation to handle large datasets.


CREATE OR REPLACE SCHEMA IDENTIFIER ($poc_owner_schema);

USE ROLE securityadmin;
CREATE OR REPLACE ROLE IDENTIFIER ($poc_owner_role) COMMENT ='POC.poc_owner Role';

GRANT ROLE IDENTIFIER ( $poc_owner_role  ) TO ROLE securityadmin;


GRANT USAGE   ON DATABASE  IDENTIFIER ($poc_database ) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT USAGE   ON WAREHOUSE IDENTIFIER ($poc_warehouse) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT MONITOR ON WAREHOUSE IDENTIFIER ($poc_warehouse) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT OPERATE ON WAREHOUSE IDENTIFIER ($poc_warehouse) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT USAGE   ON SCHEMA    IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT USAGE   ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT MONITOR ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);


GRANT MODIFY                     ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE TABLE               ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE VIEW                ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE SEQUENCE            ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE FUNCTION            ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE PROCEDURE           ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE STREAM              ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE MATERIALIZED VIEW   ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE FILE FORMAT         ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE TAG                 ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE EXTERNAL TABLE      ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE PIPE                ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE STAGE               ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);
GRANT CREATE TASK                ON SCHEMA IDENTIFIER ($poc_owner_schema) TO ROLE IDENTIFIER ($poc_owner_role);

GRANT MONITOR ON DATABASE IDENTIFIER ($poc_database) TO ROLE IDENTIFIER ($poc_owner_role);

