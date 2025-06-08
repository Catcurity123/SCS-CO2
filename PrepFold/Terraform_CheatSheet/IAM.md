#### 1. IAM 

##### 1.1 What is in IAM Policy

```
  + resource "aws_iam_policy" "assume_creator" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + id               = (known after apply)
      + name             = "AssumeCreatorRole"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "sts:AssumeRole",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:iam::730335572253:role/AccessorS3FullAccessRole"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }
```

##### 1.2 What is in IAM user

```
  + resource "aws_iam_user" "accessor_user" {
      + arn           = (known after apply)
      + force_destroy = false
      + id            = (known after apply)
      + name          = "s3-access-user"
      + path          = "/"
      + tags_all      = (known after apply)
      + unique_id     = (known after apply)
    }
```

##### 1.3 What is in IAM policy attachment 

```
  + resource "aws_iam_user_policy_attachment" "attach_assume_policy" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + user       = "s3-access-user"
    }
```

##### 1.5 What is in IAM role

```
  + resource "aws_iam_role" "accessor_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::314785338558:root"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "AccessorS3FullAccessRole"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)
    }
```


