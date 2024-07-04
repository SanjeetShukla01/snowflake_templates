USE ROLE SECURITYADMIN;
SHOW USERS;

ALTER USER <Snowflake SE User>
SET disabled = TRUE;

DROP USER <Snowflake SE User>;

SET monitor_owner_role = 'monitor_owner_role';
SET monitor_warehouse  = 'monitor_wh';

USE ROLE sysadmin;
CREATE OR REPLACE WAREHOUSE IDENTIFIER ( $monitor_warehouse ) WITH
WAREHOUSE_SIZE      = 'X-SMALL'
AUTO_SUSPEND        = 60
AUTO_RESUME         = TRUE
MIN_CLUSTER_COUNT   = 1
MAX_CLUSTER_COUNT   = 4
SCALING_POLICY      = ‘STANDARD’
INITIALLY_SUSPENDED = TRUE;


USE ROLE securityadmin;

CREATE OR REPLACE ROLE IDENTIFIER ( $monitor_owner_role );
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE IDENTIFIER (
$monitor_owner_role );
GRANT USAGE   ON WAREHOUSE IDENTIFIER ( $monitor_warehouse ) TO ROLE
IDENTIFIER ( $monitor_owner_role  );
GRANT OPERATE ON WAREHOUSE IDENTIFIER ( $monitor_warehouse ) TO ROLE
IDENTIFIER ( $monitor_owner_role  );

GRANT ROLE IDENTIFIER ( $monitor_owner_role )
TO USER <Your User Here>;


USE ROLE      IDENTIFIER ( $monitor_owner_role );
USE WAREHOUSE IDENTIFIER ( $monitor_warehouse  );


SELECT start_time,
       role_name,
       database_name,
       schema_name,
       user_name,
       query_text,
       query_id
FROM   snowflake.account_usage.query_history
WHERE  role_name = 'ACCOUNTADMIN'
ORDER BY start_time DESC;


SELECT start_time,
       role_name,
       database_name,
       schema_name,
       user_name,
       query_text,
       query_id
FROM   TABLE ( snowflake.information_schema.query_history())
WHERE  role_name = 'ACCOUNTADMIN'
ORDER BY start_time DESC;


## Network Policy: To restrict access to known IP ranges, you
implement network policies.

Note: It is not possible to SET a network policy that prevents access from the current
session. We prove this assertion later in this chapter.

USE ROLE accountadmin;
CREATE OR REPLACE NETWORK POLICY my_network_policy ALLOWED_IP_LIST = (
'192.168.0.0/22', '192.168.0.1/24' );

ALTER ACCOUNT SET network_policy = my_network_policy;

-- Create a Third-Party-Specific Network Policy
USE ROLE accountadmin;

CREATE OR REPLACE NETWORK POLICY powerbi_gateway_policy ALLOWED_IP_LIST=(
'192.168.0.2' );

USE ROLE securityadmin;
CREATE OR REPLACE USER test
PASSWORD             = 'test'
DISPLAY_NAME         = 'Test User'
EMAIL                = 'test@test.xyz'
DEFAULT_ROLE         = 'monitor_owner_role'
DEFAULT_NAMESPACE    = 'SNOWFLAKE.reader_owner'
DEFAULT_WAREHOUSE    = 'monitor_wh'
COMMENT              = 'Test user'
NETWORK_POLICY       = powerbi_gateway_policy
MUST_CHANGE_PASSWORD = FALSE;

-- To see existing network policies.
USE ROLE accountadmin;
SHOW NETWORK POLICIES IN ACCOUNT;

-- # To see the IP ranges:
DESCRIBE NETWORK POLICY my_network_policy;
DESCRIBE NETWORK POLICY powerbi_gateway_policy;

--To identify whether an account-level network policy is active or not:
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;

-- To convert output of above show statement to resultset, use table function:
SELECT "key", "value", "level"
FROM TABLE ( RESULT_SCAN ( last_query_id()));


--Teardown
USE ROLE accountadmin;
ALTER ACCOUNT UNSET network_policy;
DROP NETWORK POLICY my_network_policy;
DROP NETWORK POLICY powerbi_gateway_policy;
USE ROLE securityadmin;

ALTER USER test UNSET network_policy;
DROP USER      test;
DROP ROLE      monitor_owner_role;
DROP WAREHOUSE monitor_wh;

-- Recertification of Users time to time
-- Checking active users for Recertification purpose
USE ROLE accountadmin;
SELECT name,
       owner,
       comment
FROM   snowflake.account_usage.roles
WHERE  deleted_on IS NULL
ORDER BY name ASC;

-- In above result all roles with owner set as NULL are snowflake reserved roles.

SELECT ur.role,
       ur.grantee_name,
       r.owner
FROM   snowflake.account_usage.roles          r,
       snowflake.account_usage.grants_to_users ur
WHERE  r.name        = ur.role
AND    r.deleted_on  IS NULL
AND    ur.deleted_on IS NULL
ORDER BY r.name ASC;

-- Once you confirm that the roles have correctly been assigned to users,
-- Next review is to check all object entitlements are correct for each role:

SELECT r.name,
       gr.privilege,
       gr.table_catalog||'.'||gr.table_schema||'.'||gr.name AS object_name
FROM   snowflake.account_usage.roles          r,
       snowflake.account_usage.grants_to_roles gr
WHERE  r.name        = gr.name
AND    r.deleted_on  IS NULL
AND    gr.deleted_on IS NULL
ORDER BY r.name ASC;

-- Above queries satisfy the first three requirements: identifying roles for administration
-- users, service users, and end users and then validating the entitlements granted to each role.

-- Data Shares

USE ROLE accountadmin;
USE WAREHOUSE monitor_wh;
SHOW shares;
SELECT "kind",
       "name",
       "database_name",
       "owner",
       "to",
       "listing_global_name"
FROM TABLE ( RESULT_SCAN ( last_query_id()))
ORDER BY "kind", "name";

DESCRIBE SHARE <share name here>;

SELECT "kind",
       "name",
       "shared_on"
FROM TABLE ( RESULT_SCAN ( last_query_id()))
ORDER BY "kind", "name";

DESCRIBE SHARE snowflake.account_usage;

//
--With all data share information to hand, you can now determine the consuming
--Snowflake accounts along with the objects available within each data share to validate
--the correctness of data distribution.
//


--Reader Accounts: Used for reading snowflake data generally they are external users.


--Creating a Reader Account
USE ROLE accountadmin;
SHOW MANAGED ACCOUNTS;

CREATE MANAGED ACCOUNT reader_acct1
ADMIN_NAME     = user1,
ADMIN_PASSWORD = 'Sdfed43da!44',
TYPE           = READER;


-- Identifying Managed Accounts
SHOW MANAGED ACCOUNTS;
SELECT "name",
       "cloud",
       "region",
       "locator",
       "url"
FROM TABLE ( RESULT_SCAN ( last_query_id()))
ORDER BY "name" ASC;

-- Cleanup
DROP MANAGED ACCOUNT reader_acct1;



-- Login History
-- Note: latency period for  login_history is up to 2 hours.
USE ROLE accountadmin;

SELECT event_id,
       event_type,
       user_name,
       error_code,
       error_message
FROM   snowflake.account_usage.login_history
WHERE  error_message IS NOT NULL
ORDER BY event_timestamp DESC;



-- Query History
-- Note the latency period for query_history is up to 45 minutes.
USE ROLE accountadmin;

ELECT user_name,
       query_id,
       query_text,
       start_time
FROM   snowflake.account_usage.query_history
WHERE  query_text ILIKE '%ACCOUNTADMIN%'
ORDER BY start_time DESC;


-- Access History: Latency period for access_history is 3 hours.
USE ROLE accountadmin;

SELECT user_name,
       query_id,
       direct_objects_accessed,
       base_objects_accessed,
       objects_modified,
       query_start_time
FROM   snowflake.account_usage.access_history
ORDER BY query_start_time DESC
LIMIT 10;

//
-- Access nested JSON attributes within access_history.direct_objects_accessed
--and joins with query_history to facilitate time-banded queries:
//
SELECT ah.user_name,
       ah.query_id,
       ah.direct_objects_accessed,
       doa.value:"objectDomain"::string            AS doa_object_domain,
       doa.value:"objectName"::string              AS doa_base_object,
       doa2.value:"columnName"::string             AS doa_column_name,
       ah.base_objects_accessed,
       boa.value:"objectDomain"::string            AS boa_object_domain,
       boa.value:"objectName"::string              AS boa_base_object,
       ah.objects_modified,
       om.value:"objectDomain"::string             AS om_object_domain,
       om.value:"objectName"::string               AS om_base_object,
       ah.query_start_time
FROM   snowflake.account_usage.access_history               ah,
       snowflake.account_usage.query_history                qh,
       LATERAL FLATTEN ( direct_objects_accessed          ) doa,
       LATERAL FLATTEN ( doa.value:columns, OUTER => TRUE ) doa2,
       LATERAL FLATTEN ( base_objects_accessed            ) boa,
       LATERAL FLATTEN ( objects_modified                 ) om
WHERE  ah.query_id                                 = qh.query_id
AND    doa.value:"objectDomain"::string            = 'Table'
AND    doa_base_object                             = '<Your Table Here>'
AND    qh.start_time
> DATEADD ( month, -1,
current_timestamp())
ORDER BY ah.query_start_time DESC;


--Below SQL statement further joins to account_usage.tables to provide the capability
--to filter by database, schema, and table.

SELECT ah.user_name,
       ah.query_id,
       ah.direct_objects_accessed,
       doa.value:"objectDomain"::string            AS doa_object_domain,
       doa.value:"objectName"::string              AS doa_base_object,
       ah.base_objects_accessed,
       boa.value:"objectDomain"::string            AS boa_object_domain,
       boa.value:"objectName"::string              AS boa_base_object,
       ah.objects_modified,
       om.value:"objectDomain"::string             AS om_object_domain,
       om.value:"objectName"::string               AS om_base_object,
       ah.query_start_time
FROM   snowflake.account_usage.access_history      ah,
       snowflake.account_usage.query_history       qh,
       snowflake.account_usage.tables              t,
       LATERAL FLATTEN ( direct_objects_accessed ) doa,
       LATERAL FLATTEN ( base_objects_accessed   ) boa,
       LATERAL FLATTEN ( objects_modified        ) om
WHERE  ah.query_id                                 = qh.query_id
AND    doa.value:"objectId"::int
= t.table_id
AND    doa.value:"objectDomain"::string            = 'Table'
AND    t.table_catalog                             = '<Your Database Here>'
AND    t.table_schema                             = '<Your Schema Here>'
AND    t.table_name                                = '<Your Table Here>'
AND    t.deleted IS NULL
AND    qh.start_time
> DATEADD ( month, -1,
current_timestamp())
ORDER BY ah.query_start_time DESC;



--Preserving Login History.

SET monitor_owner_role     = 'monitor_owner_role';
SET monitor_warehouse      = 'monitor_wh';
SET monitor_database       = 'MONITOR';
SET monitor_owner_schema   = 'MONITOR.monitor_owner';
USE ROLE sysadmin;
CREATE OR REPLACE DATABASE IDENTIFIER ( $monitor_database ) DATA_RETENTION_
TIME_IN_DAYS = 90;
CREATE OR REPLACE SCHEMA IDENTIFIER ( $monitor_owner_schema );
USE ROLE securityadmin;


GRANT USAGE   ON DATABASE  IDENTIFIER ( $monitor_database       ) TO ROLE
IDENTIFIER ( $monitor_owner_role  );
GRANT USAGE   ON SCHEMA    IDENTIFIER ( $monitor_owner_schema   ) TO ROLE
IDENTIFIER ( $monitor_owner_role  );
GRANT USAGE                      ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT MONITOR                    ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT MODIFY                     ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE TABLE               ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE VIEW                ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE SEQUENCE            ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE FUNCTION            ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE PROCEDURE           ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE STREAM              ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE MATERIALIZED VIEW   ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE FILE FORMAT         ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );
GRANT CREATE TAG                 ON SCHEMA IDENTIFIER ( $monitor_owner_
schema   ) TO ROLE IDENTIFIER ( $monitor_owner_role );

--With your database created, you must first set your context:
USE ROLE      monitor_owner_role;
USE WAREHOUSE monitor_wh;
USE DATABASE  MONITOR;
USE SCHEMA    monitor_owner;


CREATE TABLE aud_login_history
AS
SELECT *
FROM   snowflake.account_usage.login_history;


USE ROLE securityadmin;
GRANT CREATE TASK ON SCHEMA monitor.monitor_owner TO ROLE monitor_owner_role;

--Revert to monitor_owner_role:
USE ROLE monitor_owner_role;

SELECT MAX ( event_timestamp )
FROM   monitor.monitor_owner.aud_login_history;


SELECT *
FROM   snowflake.account_usage.login_history
WHERE  event_timestamp >
       (
       SELECT MAX ( event_timestamp )
       FROM   monitor.monitor_owner.aud_login_history
       );



INSERT INTO monitor.monitor_owner.aud_login_history
SELECT *
FROM   snowflake.account_usage.login_history
WHERE  event_timestamp >
       (
       SELECT MAX ( event_timestamp )
       FROM   monitor.monitor_owner.aud_login_history
       );

-- Create at task to do regular insert
CREATE OR REPLACE TASK task_aud_login_history_load
WAREHOUSE = monitor_wh
SCHEDULE = 'USING CRON 0 2 L 1-12 * GMT'
AS
INSERT INTO monitor.monitor_owner.aud_login_history
SELECT *
FROM   snowflake.account_usage.login_history
WHERE  event_timestamp >
       (
       SELECT MAX ( event_timestamp )
       FROM   monitor.monitor_owner.aud_login_history
       );


--Cleanup
USE ROLE       accountadmin;
DROP ROLE      monitor_owner_role;
DROP WAREHOUSE monitor_wh;
DROP DATABASE  monitor;
DROP TASK      task_aud_login_history_load;



