# AWS CLI CheatSheet

## aws configure
(+) To view all profiles in a machine: `aws configure list-profiles`.
==> Alternatively, we can also `nano ~/.aws/config` to view and edit all profiles.

(+) To list all information about an entity" `aws configure list --profile <profile-name>`

(+) To edit or add a new profile" `aws configure --profile <profile-name>`

## AWS Session
(+) To use a particular profiles in a session: `export AWS_PROFILE=<profile-name>`.
==> To make a default profile or session, we can include  `export AWS_PROFILE=<profile-name>` in `.bashrc`
==> To test if the session is correctly set, we can use `echo $AWS_PROFILE` to see the session and then `aws sts get-caller-identity` to retrieve account information.

## AWS IAM
(+) To list all users in the account: `aws iam list-users`.

(+) We can do the same for groups: `aws iam list-groups`.

(+) To know what user is in what group: `aws iam list-groups-for-user --user-name <username>`

(+) To list all policies attached to an user: `aws iam list-attached-user-policies --user-name <username>`

(+) To get what the policy is about: `aws iam get-policy-version --policy-arn arn:aws:iam::891376942137:policy/S3BucketLevelOnlyPolicy --version-id v1`

(+) To get the ARN of a policy: `aws iam list-policies --query "Policies[?PolicyName=='<policy_name>'].Arn"`

(+) To create access key for a user: `aws iam create-access-key --user-name <username>`

(+) To assume a role: 

```
    aws sts assume-role --role-arn <role-arn> \
    --role-session-name <mysession> \
    --duration-seconds <time-in-seconds-900>
```

``` Example
aws sts assume-role --role-arn arn:aws:iam::992382768732:role/s3-assume-role \
--role-session-name FullS3Admin \
--duration-seconds 900

```
==> After assuming the role we will have an `access key`, a `secret key`, and a `session token`. We need to use those information as a credentials for the role.

```
export AWS_ACCESS_KEY_ID=your-temporary-access-key-id
export AWS_SECRET_ACCESS_KEY=your-temporary-secret-access-key
export AWS_SESSION_TOKEN=your-temporary-session-token
```

===> Then we can use the Assumed role session


## AWS S3
(+) To list all buckets :`aws s3 ls -a`

(+) To list all items in a bucket: `aws s3 ls s3://test-bucket-for-labbing`

(+) To download a file from S3: `aws s3 cp <source> <destination>`

(+) To create a presign URL from S3 object: `aws s3 presign s3://<bucket>/<object> --expires-in <time in ms>` 

