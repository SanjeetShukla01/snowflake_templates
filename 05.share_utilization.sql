--Data Sharing Monitoring
USE ROLE accountadmin;
SHOW shares;


SELECT "created_on", "kind", "name",
       "database_name", "to", "owner", "listing_global_name"
FROM TABLE ( RESULT_SCAN ( last_query_id()));


--List the consumers of a named share:
SHOW GRANTS OF SHARE SNOWFLAKE.ACCOUNT_USAGE;

SELECT OBJECT_CONSTRUCT ( * ) FROM   TABLE ( RESULT_SCAN ( last_query_id()));




-- Private listings are easily monitored

SELECT DATE_TRUNC ( 'DAY', query_date )      AS query_day,
       SUM ( 1 )                             AS num_requests,
       listing_objects_accessed,
       exchange_name,
       cloud_region,
       listing_global_name,
       provider_account_locator,
       provider_account_name,
       share_name,
       consumer_account_locator,
       consumer_account_name,
       consumer_account_organization
FROM   snowflake.data_sharing_usage.listing_access_history
WHERE  DATE_TRUNC ( 'DAY', query_date ) >=
       DATEADD ( day, -7, DATE_TRUNC ( 'DAY', current_date()))
GROUP BY DATE_TRUNC ( 'DAY', query_date ),
         listing_objects_accessed,
         exchange_name,
         cloud_region,
         listing_global_name,
         provider_account_locator,
         provider_account_name,
         share_name,
         consumer_account_locator,
         consumer_account_name,
         consumer_account_organization
ORDER BY DATE_TRUNC ( 'DAY', query_date ),
         listing_objects_accessed ASC;




-- Listing Telemetry daily view

SELECT DATE_TRUNC ( 'DAY', event_date )      AS event_date,
       exchange_name,
       snowflake_region,
       listing_name,
       listing_display_name,
       listing_global_name,
       event_type,
       action,
       consumer_accounts_daily,
       consumer_accounts_28D
FROM   snowflake.data_sharing_usage.listing_telemetry_daily
WHERE  DATE_TRUNC ( 'DAY', event_date ) >=
       DATEADD ( day, -7, DATE_TRUNC ( 'DAY', current_date()))
ORDER BY DATE_TRUNC ( 'DAY', event_date ) ASC;



-- Marketplace paid listing

SELECT event_date,
       event_type,
       invoice_date,
       listing_name,
       listing_display_name,
       listing_global_name,
       charge_type,
       gross,
       fees,
       taxes,
       net_amount,
       currency
FROM   snowflake.data_sharing_usage.marketplace_disbursement_report;


-- Listing subscriptions
SELECT report_date,
       usage_date,
       provider_name,
       provider_account_name,
       provider_account_locator,
       provider_organization_name,
       listing_display_name,
       listing_global_name,
       database_name,
       po_number,
       pricing_plan,
       charge_type,
       units,
       unit_price,
       charge,
       currency
FROM   snowflake.data_sharing_usage.marketplace_paid_usage_daily;


-- Marketplace daily purchases
SELECT event_date,
       event_type,
       consumer_account_locator,
       consumer_account_name,
       listing_name,
       listing_display_name,
       listing_global_name,
       pricing_plan,
       user_metadata
FROM   snowflake.data_sharing_usage.marketplace_purchase_events_daily;





