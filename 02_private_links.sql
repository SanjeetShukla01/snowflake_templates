USE ROLE accountadmin;
SELECT system$get_privatelink(
       '<Your AWS Account ID Here>',
       '{
           "Credentials": {
               "AccessKeyId": "<Your Access Key Here>",
               "SecretAccessKey": "<Your Secret Access Key Here>",
               "SessionToken": "<Your Session Token Here>",
               "Expiration": "<Your Expiry Time Here>"
           },
           "FederatedUser": {
               "FederatedUserId": "<Your AWS Account ID Here>:snowflake",
               ␇"Arn": "arn:aws:sts:: <Your AWS Account ID Here>:federated-
user/snowflake"
           },
           "PackedPolicySize": 0
       }' );



-- The expected response is “Private link access not authorized.” or for later checks
-- where system$authorise_privatelink() has been executed, “Private link access authorized.”



-- Having verified that your PrivateLink access is not authorized, you can now enable PrivateLink:


USE ROLE accountadmin;
SELECT system$authorize_privatelink(
       '<Your AWS Account ID Here>',
       '{
           "Credentials": {
               "AccessKeyId": "<Your Access Key Here>",
               "SecretAccessKey": "<Your Secret Access Key Here>",
               "SessionToken": "<Your Session Token Here>",
               "Expiration": "<Your Expiry Time Here>"
           },
          "FederatedUser": {
              "FederatedUserId": "<Your AWS Account ID Here>:snowflake",
              ␇"Arn": "arn:aws:sts:: <Your AWS Account ID Here>:federated-
user/snowflake"
          },
          "PackedPolicySize": 0
      }' );



---␇Revoking PrivateLink

SELECT system$revoke_privatelink(
       '<Your AWS Account ID Here>',
       '{
           "Credentials": {
               "AccessKeyId": "<Your Access Key Here>",
               "SecretAccessKey": "<Your Secret Access Key Here>",
               "SessionToken": "<Your Session Token Here>",
               "Expiration": "<Your Expiry Time Here>"
           },
          "FederatedUser": {
              "FederatedUserId": "<Your AWS Account ID Here>:snowflake",
              ␇"Arn": "arn:aws:sts:: <Your AWS Account ID Here>:federated-
user/snowflake"
          },
          "PackedPolicySize": 0
      }' );







--␇Identifying PrivateLink Endpoints

USE ROLE accountadmin;
SELECT system$get_privatelink_authorized_endpoints();




USE ROLE accountadmin;
SELECT REPLACE ( value:endpointId,     '"' ) AS AccountID,
       REPLACE ( value:endpointIdType, '"' ) AS CSP
FROM   TABLE (
          FLATTEN input => parse_json(system$get_privatelink_authorized_endpoints())
     )
             );



-- Configuring AWS VPC endpoint
USE ROLE accountadmin;
SELECT REPLACE ( value, '"' ) AS privatelink_vpce_id
FROM   TABLE (
          FLATTEN (
                  input => parse_json(system$get_privatelink_config())
                  )
             )
WHERE  key = 'privatelink-vpce-id';

-- The private link vpc id may look like com.amazonaws.vpce.eu-west-2.vpce-svc-0839061a5300e5ac1
-- You can use private link account url to get private link vpc id as shown below. 


SELECT current_region();


USE ROLE accountadmin;
SELECT REPLACE ( value, '"' ) AS privatelink_vpce_id
FROM   TABLE (
          FLATTEN (
                  input => parse_json(system$get_privatelink_config())
                  )
             )
WHERE  key = 'privatelink-account-url';



