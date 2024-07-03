## Private Link

AWS PrivateLink is an AWS service for creating private VPC endpoints that allow direct, secure connectivity between your AWS VPCs and the Snowflake VPC without traversing the public Internet. The connectivity is for AWS VPCs in the same AWS region.
https://docs.snowflake.com/en/user-guide/admin-security-privatelink

## Steps to create Private Link:
This part relies on AWS-supplied policies for CloudShell (AWS CloudShellFullAccess) and for EC2 (AmazonEC2FullAccess). However, there is no AWS supplied policy for STS, so you must therefore create your own.

- Begin by searching within AWS console for IAM, select Policies, and then click Create Policy.
- In the policy Json box paste this json for STS policy.
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "STS",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole",
                "sts:GetFederationToken"
            ],
            "Resource": "*"
        }
    ]
}
```

## Steps Writedown
- Step-1 Create STS Profile
	- IAM, select Policies, and then click Create Policy.
	- In the policy Json box paste this json for STS policy.
	
	- Name the policy as snowflake_private_link_policy
- Step-2 Creating IAM User, snowflake_private_link_user
	- Allow Programmatic access and AWS management console access.
	- In the permission assign following permissions
	- AWSCLousShellFullAccess, AmazonEC2FullAccess, snowflake_private_link_policy 

