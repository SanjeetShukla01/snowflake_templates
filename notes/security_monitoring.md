# Ways to monitor, control, and manage your Snowflake estate. 
Policy, Process, Procedure,  

-- Accountadmin usage should be restricted to platform specific activities.
-- Create a break-glass user for emergency purpose. 

Identify monitoring recipient
Pre use notification, Develop mechanism to notify before accountadmin is going to be used.

```sql
    USE ROLE SECURITYADMIN;
    SHOW USERS;
```


## Checklist:
Policy signed off?
Process signed off?
Snowflake Sales Engineering users disabled?
“Break glass” user managed by PAM?
Event source identified?
All monitoring recipients identified?
All monitoring recipients engaged and trained?
Event payload documented and agreed?
Event response plan agreed?
Event payload delivery mechanism implemented?
Event audit trail implemented?
Event preplanned activity notification process agreed?
Procedures implemented?
Operations Manual updated?
Last review date:

Attempting to set the account network policy from an IP range not included within
the allowed_ip_list results in an error:

Error:
```shell
Network policy MY_NETWORK_POLICY cannot be activated.
Requestor IP address, <Your IP Address here>, must be included in
the allowed_ip_list.
To add the specific IP, execute command “ALTER NETWORK
POLICY MY_NETWORK_POLICY SET ALLOWED_IP_LIST=
('192.168.0.0/22','192.168.0.1/24','<Your IP Address here>');”.
Similarly, a CIDR block of IP addresses can be added instead of the
specific IP address.
```

If your Internet connection uses DHCP, your IP may change between sessions.
Ensure you UNSET your network policy before disconnecting!

`SHOW NETWORK POLICIES IN ACCOUNT;`
The SHOW command accesses the Snowflake Global Services Layer, which itself is
based upon FoundationDB, they key-pair store that underpins all Snowflake metadata
operations.


Share Monitoring 
Tri-Secret Secure
Data Masking
Multiple Failed Logins

Cleanup
Having created various objects within this chapter, you now reset your account by
removing each object in turn:

USE ROLE accountadmin;
ALTER ACCOUNT UNSET network_policy;
DROP NETWORK POLICY my_network_policy;
DROP NETWORK POLICY powerbi_gateway_policy;
USE ROLE securityadmin;

ALTER USER test UNSET network_policy;
DROP USER      test;
DROP ROLE      monitor_owner_role;
DROP WAREHOUSE monitor_wh;

Periodic Access Recertification

Security Information and Event Management (SIEM)

Preserving Login History. 