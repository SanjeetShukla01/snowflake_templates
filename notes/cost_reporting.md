## Cost Drivers.
- Compute Cost: Pipes, Clustering, Usage (reader account), Warehouse
- Storage Cost: Tables, Internal Stages, Materialized Views
- Data Transfer Cost: Data Replication, External stages

![stages.png](../images/stages.png)

## Identifying Consumption Metrics:
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