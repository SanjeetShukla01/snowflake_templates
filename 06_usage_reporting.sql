USE ROLE      monitor_owner_role;
USE WAREHOUSE monitor_wh;
USE DATABASE  monitor;
USE SCHEMA    monitor.monitor_owner;


CREATE OR REPLACE TABLE employee
(
preferred_name            VARCHAR(255),
surname_preferred         VARCHAR(255),
forename_preferred        VARCHAR(255),
gender                    VARCHAR(255)
);


CREATE OR REPLACE VIEW v_employee
AS
SELECT *
FROM   employee;


CREATE OR REPLACE TAG PII
COMMENT = 'Personally Identifiable Information';

CREATE OR REPLACE TAG PII_S_Name
COMMENT = 'Personally Identifiable Information -> Sensitive -> Name';

CREATE OR REPLACE TAG PII_N_Gender
COMMENT = 'Personally Identifiable Information -> Non-Sensitive -> Gender';




ALTER TABLE monitor.monitor_owner.employee
SET TAG PII = 'Personally Identifiable Information';

ALTER TABLE monitor.monitor_owner.employee
MODIFY COLUMN preferred_name
SET TAG PII_S_Name = 'Personally Identifiable Information -> Sensitive -> Name';

ALTER TABLE monitor.monitor_owner.employee
MODIFY COLUMN surname_preferred
SET TAG PII_S_Name = 'Personally Identifiable Information -> Sensitive -> Name';

ALTER TABLE monitor.monitor_owner.employee
MODIFY COLUMN forename_preferred
SET TAG PII_S_Name = 'Personally Identifiable Information -> Sensitive -> Name';


ALTER TABLE monitor.monitor_owner.employee
MODIFY COLUMN gender
SET TAG PII_N_Gender = 'Personally Identifiable Information -> Non-Sensitive -> Gender';



-- Searching by Object Tag

SHOW tags IN SCHEMA monitor.monitor_owner;
SELECT *
FROM   snowflake.account_usage.tags
WHERE  deleted IS NULL
ORDER BY tag_name;



SELECT *
FROM   snowflake.account_usage.tag_references
WHERE  object_deleted IS NULL
ORDER BY tag_name;


--  Create a tag reference view
CREATE OR REPLACE VIEW v_tag_references COPY GRANTS
AS
SELECT tag_name,
       object_database||'.'||
       object_schema  ||'.'||
       object_name           AS target_object,
       tag_database||'.'||
       tag_schema  ||'.'||
       tag_name              AS tag_source,
       CASE
          WHEN column_name IS NULL THEN object_database||'.'||object_
schema||'.'||object_name
          ELSE object_database||'.'||object_schema||'.'||object_
name||'.'||column_name
       END                   AS target,
       domain
FROM   snowflake.account_usage.tag_references
WHERE  object_deleted IS NULL
ORDER BY tag_name, target_object, target;


SELECT * FROM   v_tag_references;

USE ROLE securityadmin;
CREATE OR REPLACE ROLE self_service_reader_role;


GRANT USAGE   ON DATABASE  MONITOR               TO ROLE self_service_reader_role;
GRANT USAGE   ON WAREHOUSE monitor_wh            TO ROLE self_service_reader_role;
GRANT OPERATE ON WAREHOUSE monitor_wh            TO ROLE self_service_reader_role;
GRANT USAGE   ON SCHEMA    monitor.monitor_owner TO ROLE self_service_reader_role;


GRANT SELECT ON ALL    VIEWS IN SCHEMA monitor.monitor_owner TO ROLE self_service_reader_role;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA monitor.monitor_owner TO ROLE self_service_reader_role;

GRANT ROLE self_service_reader_role TO ROLE sysadmin;
GRANT ROLE self_service_reader_role TO USER <Your User Here>;


ACCOUNTADMIN: SHOW tags IN SCHEMA monitor.monitor_owner        -- works fine.
SECURITYADMIN: SHOW tags IN SCHEMA monitor.monitor_owner       -- works fine.
SYSADMIN: SHOW tags IN SCHEMA monitor.monitor_owner            -- works fine.
USERADMIN: SHOW tags IN SCHEMA monitor.monitor_owner fails.
PUBLIC: SHOW tags IN SCHEMA monitor.monitor_owner fails.

USE ROLE self_service_reader_role;
SELECT * FROM   v_tag_references;



SELECT current_available_roles();


