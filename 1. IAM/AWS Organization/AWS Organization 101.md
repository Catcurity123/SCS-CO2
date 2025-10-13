#### 1. Why AWS Organization?
(+) Different AWS Account for different business needs have different billing methods and IAM properties.

![[Pasted image 20250926132954.png]]

(+) We use one Account called `Management Account` for the primary control point of our organization. This account will send invitation to other accounts into the organization.

![[Pasted image 20250926133222.png]]
(+) Should they accept the offer, the account will join `AWS Organization` and subsequently become the `Member Accounts` of the organization.

![[Pasted image 20250926133623.png]]
(+) The root is automatically created when an organization is created and sits at the top of the hierarchy; all OUs and accounts are ultimately beneath it and inherit policies attached at the root level.

(+) An OU is a logical grouping of AWS accounts and can contain other nested OUs to build a tree structure, enabling targeted policy application to subsets of accounts based on function, environment, or compliance needs

(+) One of the key strength of `AWS Organization` is `Consolidated Billing`, where billing of Member Accounts is disabled and passed down to `Management Account.`

![[Pasted image 20250926133751.png]]

#### 2. Service Control Policies
(+) SCP is a JSON document that is applied to the whole `organization` or `individual Organization unit` or applied to `individual AWS Account`.
(+) `Management Account` is not affected by `SCP`, therefore, it is not normally used for any AWS Resource.
(+) SCPs are `account permissions boundaries` meaning they limit what the account (including account root user) can do.
(+) SCPs don't grant any permission, they are there to act as a boundary for what an account can and cant do. SCPs has `FullAWSAccess` right by default. 

![[Pasted image 20250926135848.png]]

(+) `SCP` can be attached to the Organization, The OU or the account.

###### Allow list and Deny list
(+) `Allows list` denies everything by default and only allows required permissions
(+) `Deny list` allows everything by default and only denies required permissions.

==> The permission right of an entity with SCP is the overlap between rights of the account itself and rights present in SCP
![[Pasted image 20240103114956.png | 500]]


