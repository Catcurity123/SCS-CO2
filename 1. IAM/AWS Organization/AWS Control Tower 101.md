#### A. What is it?
(+) Quick and Easy setup of multi-account environment
(+) Orchestrates other AWS services to provide this functonality.
(+) Organizations, IAM Identity Center, CloudFormation, Config and more,...

(+) `Landing Zone` - `Multi-account` environment. Can facilitate SSO/ID Federation, Centralized Logging & Auditing.
(+) `Guard Rails` - `Detect/Mandate` and `Standardize` new account creation.

![[Pasted image 20250615115329.png]]

(+) A `Management Account` will be used to create the `Control Tower`, at the hear of this account, several functionalities are employed. `AWS SSO` for ID Federation, `AWS Organization` for customizing OU, `Control Tower` itself will use `CloudFormation` and Config to develop Account Factory that will provision accounts. `AWS Config` for creating GuardRails for created accounts.

###### A1. Landing Zone
(+) This is a well architected multi-account environment for a `Home Region`, built by AWS Organization, Config, CloudFormation
(+) Security OU - Log Archive & Audit Accounts (CloudTrail & Config Logs)
(+) Sandbox OU - Test/less rigid security
(+) IAM Identity Center (AWS SSO) - SSO, multiple-accounts, ID Federation
(+) Monitoring and Notification - CloudWatch and SNS
(+) End User account provisioning via Service Catalog.

###### A2. Guard Rails
(+) Guard Rails are rules - multi-account governance
(+) `Mandatory`, `Strongly Recommended` or `Elective`
(+) `Preventive` - Stop you doing things (AWS ORG SCP)
(+) `Detective` - Compliance checks (AWS CONFIG Rules)

###### A3. Account Factory
(+) Automated Account Provisioning, cloud admins or end users (with appropriate permissions)
(+) `Guardrails` - automatically added
(+) Account admin given to a named user (IAM Identity Center).
