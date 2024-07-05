--## Identifying Consumption Metrics:
USE ROLE accountadmin;
SELECT current_account();

SELECT current_region()  AS current_region,
       current_account() AS current_account,
       service_type,
       usage_date,
       credits_billed,
       current_timestamp() AS extract_timestamp
FROM   snowflake.account_usage.metering_daily_history
ORDER BY service_type, usage_date DESC;


-- Capturing Consumption Metrics

USE ROLE sysadmin;
CREATE OR REPLACE DATABASE cost_reporting
DATA_RETENTION_TIME_IN_DAYS = 90;

CREATE OR REPLACE SCHEMA cost_reporting.cost_owner;


CREATE OR REPLACE WAREHOUSE cost_wh WITH
WAREHOUSE_SIZE      = 'X-SMALL'
AUTO_SUSPEND        = 60
AUTO_RESUME         = TRUE
MIN_CLUSTER_COUNT   = 1
MAX_CLUSTER_COUNT   = 4
SCALING_POLICY      = 'STANDARD'
INITIALLY_SUSPENDED = TRUE;
USE ROLE securityadmin;
CREATE OR REPLACE ROLE cost_owner_role;


GRANT USAGE ON DATABASE cost_reporting            TO ROLE cost_owner_role;
GRANT USAGE ON SCHEMA   cost_reporting.cost_owner TO ROLE cost_owner_role;
GRANT USAGE              ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT MONITOR            ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT MODIFY             ON SCHEMA cost_reporting.cost_owner TO ROLE ­cost_
owner_role;
GRANT CREATE TABLE       ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE VIEW        ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE SEQUENCE    ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE FUNCTION    ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE PROCEDURE   ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE STREAM      ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT CREATE TAG         ON SCHEMA cost_reporting.cost_owner TO ROLE cost_
owner_role;
GRANT USAGE   ON WAREHOUSE cost_wh TO ROLE cost_owner_role;
GRANT OPERATE ON WAREHOUSE cost_wh TO ROLE cost_owner_role;
Enable access to the Account Usage Store:
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake TO ROLE cost_owner_role;
Grant the cost owner role to ACCOUNTADMIN:
GRANT ROLE cost_owner_role TO ROLE accountadmin;
Grant the cost owner role to yourself:
GRANT ROLE cost_owner_role TO USER <Your User Here>;



--Creating Source Views

USE ROLE      cost_owner_role;
USE WAREHOUSE cost_wh;
USE DATABASE  cost_reporting;
USE SCHEMA    cost_reporting.cost_owner;
Then create your wrapper view:
CREATE OR REPLACE VIEW v_metering_daily_history COPY GRANTS
AS
SELECT current_region()  AS current_region,
       current_account() AS current_account,
       service_type,
       usage_date,
       credits_billed,
       current_timestamp() AS extract_timestamp
FROM   snowflake.account_usage.metering_daily_history;


SELECT current_region,
       current_account,
       service_type,
       usage_date,
       credits_billed,
       extract_timestamp
FROM   v_metering_daily_history;



CREATE OR REPLACE TABLE stg_metering_daily_history
(
current_region      VARCHAR ( 30 ) NOT NULL,
current_account     VARCHAR ( 30 ) NOT NULL,
service_type        VARCHAR ( 30 ) NOT NULL,
usage_date          DATE,
credits_billed      NUMBER ( 38, 10 ),
extract_timestamp   TIMESTAMP_LTZ
);


ALTER TABLE stg_metering_daily_history
SET change_tracking = TRUE;


INSERT OVERWRITE INTO cost_reporting.cost_owner.stg_metering_daily_history
SELECT current_region,
       current_account,
       service_type,
       usage_date,
       credits_billed,
       extract_timestamp
FROM   cost_reporting.cost_owner.v_metering_daily_history
WHERE  usage_date = DATEADD ( 'day', -1,
                       TO_DATE (
                          DATE_PART ( 'year', extract_timestamp )||'-'||
                          DATE_PART ( 'mm',   extract_timestamp )||'-'||
                          DATE_PART ( 'day',  extract_timestamp )));


SELECT * FROM cost_reporting.cost_owner.stg_metering_daily_history;


--Creating a Task

USE ROLE accountadmin;

Set the schema for the task to reside in:
USE DATABASE  cost_reporting;
USE SCHEMA    cost_reporting.cost_owner;
Prove the ACCOUNTADMIN role can insert data into stg_metering_daily_history:
INSERT OVERWRITE INTO cost_reporting.cost_owner.stg_metering_daily_history
SELECT current_region,
       current_account,
       service_type,
       usage_date,
       credits_billed,
       extract_timestamp
FROM   cost_reporting.cost_owner.v_metering_daily_history
WHERE  usage_date = DATEADD ( 'day', -1,
                       TO_DATE (
                          DATE_PART ( 'year', extract_timestamp )||'-'||
                          DATE_PART ( 'mm',   extract_timestamp )||'-'||
                          DATE_PART ( 'day',  extract_timestamp )));






CREATE OR REPLACE TASK cost_reporting.cost_owner.task_metering_
daily_history
USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = XSMALL
SCHEDULE = '5 MINUTE'
AS
INSERT OVERWRITE INTO cost_reporting.cost_owner.stg_metering_daily_history
SELECT current_region,
       current_account,
       service_type,
       usage_date,
       credits_billed,
       extract_timestamp
FROM   cost_reporting.cost_owner.v_metering_daily_history
WHERE  usage_date = DATEADD ( 'day', -1,
                       TO_DATE (
                          DATE_PART ( 'year', extract_timestamp )||'-'||
                          DATE_PART ( 'mm',   extract_timestamp )||'-'||
                          DATE_PART ( 'day',  extract_timestamp )));


ALTER TASK cost_reporting.cost_owner.task_metering_daily_history RESUME;

SHOW tasks;


SELECT timestampdiff ( second, current_timestamp, scheduled_time ) as
next_run,
       scheduled_time,
       current_timestamp,
       name,
       state
FROM   TABLE ( information_schema.task_history())
ORDER BY completed_time DESC;


SELECT *
FROM   cost_reporting.cost_owner.stg_metering_daily_history;

--Rescheduling a Task

ALTER TASK cost_reporting.cost_owner.task_metering_daily_history SUSPEND;

ALTER TASK IF EXISTS cost_reporting.cost_owner.task_metering_daily_
history SET
SCHEDULE = 'USING CRON 0 5 * * * GMT';

ALTER TASK cost_reporting.cost_owner.task_metering_daily_history RESUME;


SELECT timestampdiff ( second, current_timestamp, scheduled_time ) as
next_run,
       scheduled_time,
       current_timestamp,
       name,
       state
FROM   TABLE ( information_schema.task_history())
ORDER BY completed_time DESC;


ALTER TASK cost_reporting.cost_owner.task_metering_daily_history SUSPEND;


-- Replication of Database
USE ROLE accountadmin;
SHOW DATABASES;
ALTER DATABASE cost_reporting ENABLE REPLICATION TO ACCOUNTS NUYMCLU.NP62160;


-- List all replication databases.
SHOW REPLICATION DATABASES;


--Ingesting a Replicated Database

SE ROLE accountadmin;
CREATE DATABASE nuymclu_replication_tertiary_cost_reporting
AS REPLICA OF nuymclu.replication_tertiary.cost_reporting
DATA_RETENTION_TIME_IN_DAYS = 90;

ALTER DATABASE nuymclu_replication_tertiary_cost_reporting REFRESH;

SELECT *
FROM   nuymclu_replication_tertiary_cost_reporting.cost_owner.stg_metering_daily_history;



CREATE TASK nuymclu_replication_tertiary_cost_reporting_task
WAREHOUSE            = compute_wh
SCHEDULE             = 'USING CRON 0 8 * * * GMT'
USER_TASK_TIMEOUT_MS = 14400000
AS
ALTER DATABASE nuymclu_replication_tertiary_cost_reporting REFRESH;


ALTER TASK nuymclu_replication_tertiary_cost_reporting_task RESUME;


-- Check and confirm that task is scheduled
SELECT timestampdiff ( second, current_timestamp, scheduled_time ) as
next_run,
       scheduled_time,
       current_timestamp,
       name,
       state
FROM   TABLE ( information_schema.task_history())
ORDER BY completed_time DESC;



--You should also examine the status information available for the last database refresh:
SELECT phase_name,
       result,
       start_time,
       end_time,
       details
FROM TABLE ( information_schema.database_refresh_progress ( nuymclu_replication_tertiary_cost_reporting ));




SELECT *
FROM   nuymclu_replication_tertiary_cost_reporting.cost_owner.stg_metering_daily_history;



--Creating Consumption Metrics Objects

CREATE OR REPLACE TABLE cms_metering_daily_history
(
spoke_name          VARCHAR ( 255 ) NOT NULL,
current_region      VARCHAR ( 30  ) NOT NULL,
current_account     VARCHAR ( 30  ) NOT NULL,
service_type        VARCHAR ( 30  ) NOT NULL,
usage_date          DATE,
credits_billed      NUMBER ( 38, 10 ),
extract_timestamp   TIMESTAMP_LTZ  NOT NULL,
ingest_timestamp    TIMESTAMP_LTZ  DEFAULT current_timestamp() NOT NULL
);


-- Create a stream.
CREATE STREAM strm_nuymclu_replication_tertiary_cost_reporting_metering_daily_history
ON TABLE nuymclu_replication_tertiary_cost_reporting.cost_owner.stg_metering_daily_history;



-- Create a task
CREATE OR REPLACE TASK task_load_nuymclu_replication_tertiary_cost_reporting_metering_daily_history
WAREHOUSE = cms_wh
SCHEDULE  = '5 minute'
WHEN system$stream_has_data ( 'strm_nuymclu_replication_tertiary_cost_reporting_metering_daily_history' )
AS
INSERT INTO cms_metering_daily_history
SELECT 'nuymclu_replication_tertiary_cost_reporting_metering_daily_
history',
       current_region,
       current_account,
       service_type,
       usage_date,
       credits_billed,
       extract_timestamp,
       current_timestamp()
FROM  strm_nuymclu_replication_tertiary_cost_reporting_metering_daily_
history;


ALTER TASK task_load_nuymclu_replication_tertiary_cost_reporting_metering_daily_history RESUME;




CREATE OR REPLACE VIEW v_cms_monthly_metering_daily_history
AS
SELECT spoke_name,
       current_region()  AS current_region,
       current_account() AS current_account,
       service_type,
       DECODE ( EXTRACT ( 'month', usage_date ),
                          1,  'January',
                          2,  'February',
                          3,  'March',
                          4,  'April',
                          5,  'May',
                          6,  'June',
                          7,  'July',
                          8,  'August',
                          9,  'September',
                          10, 'October',
                          11, 'November',
                          12, 'December')  AS month_of_year,
       TO_CHAR ( DATE_PART ( 'year', usage_date ))   AS billing_year,
       SUM   ( credits_billed ) AS sum_credits_billed,
       current_timestamp()      AS extract_timestamp
FROM   cms_metering_daily_history
GROUP BY spoke_name,
         service_type,
         DATE_PART ( 'Month', usage_date ),
         DATE_PART ( 'year',  usage_date );