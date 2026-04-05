#### What is context and config in AWS SDK

##### A. The Problem
(+) When your Go code calls an AWS service, it is making an HTTP request across a network to a remote server. Three things can go wrong:
    1. `Identity` — AWS needs to know who you are and do you have permission
    2. `Configuration` — your code needs to know which region, which endpoint, how to retry
    3. `Lifecycle` — the HTTP call might hang, timeout, or need to be cancelled mid-flight
`cfg` solves problems 1 and 2. `ctx` solves problem 3.

###### A1. cfg (aws.Config)
(+) `cfg` is a Go struct of type aws.Config. It is a static bundle of information that answers the question: "How should I connect to AWS?"

It contains:
    + Your AWS `credentials` (Access Key, Secret Key, Session Token)
    + Your `region` (us-east-1, ap-southeast-1, etc.)
    + The HTTP `client` to use
    + Retry `policy` (how many times to retry on failure)
    + `Endpoint` resolvers (which URL to hit for each service)

`cfg, err := config.LoadDefaultConfig(ctx)`: is a credential discovery function. It seraches for the identity.
==> It will search for env variable, local development, instance metadata (IMDS), and web identity 

``` Example
cfg = aws.Config{
    Region:      "us-east-1",
    Credentials: aws.CredentialsProviderFunc(func(ctx context.Context) (aws.Credentials, error) {
        return aws.Credentials{
            AccessKeyID:     "ASIAIOSFODNN7EXAMPLE",
            SecretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            SessionToken:    "AQoXnyc4lcK4W...",
        }, nil
    }),
    HTTPClient:   &http.Client{Timeout: 30 * time.Second},
    RetryMaxAttempts: 3,
}
```


(+) `cfg` is reusable and long-lived, once loaded we can create many different service clients from the cfg

```
cfg, _ := config.LoadDefaultConfig(ctx)

s3Client      := s3.NewFromConfig(cfg)
rdsClient     := rds.NewFromConfig(cfg)
secretsClient := secretsmanager.NewFromConfig(cfg)
```

###### A2. ctx (context.Context)
(+) `ctx` is an interface - not a struct - defined in Go's standard library

```
type Context interface {
    Deadline() (deadline time.Time, ok bool)
    Done() <-chan struct{}
    Err() error
    Value(key any) any
}
```

(+) It contains:
    1. Deadline()	When does this operation expire?
    2. Done()	A channel that closes when cancelled or expired
    3. Err()	Why was it cancelled? (timeout vs manual cancel)
    4. Value(key)	Key-value metadata attached to the context

(+) Contexts form a parent-child tree. A child inherits the parent's deadline and cancellation. If the parent is cancelled, all children are cancelled automatically.

```
context.Background()          ← root, never expires, no deadline
        │
        ▼
Lambda Runtime Context         ← has deadline = function timeout
        │
        ▼
ctx passed to your handler
        │
        ├──► ctx passed to LoadDefaultConfig
        │            │
        │            └──► ctx attached to HTTP request to metadata endpoint
        │
        └──► ctx passed to GetSecretValue
                     │
                     └──► ctx attached to HTTP POST to secretsmanager endpoint
```
==> When Lambda's timeout fires, the Lambda Runtime Context is cancelled. This cancellation propagates down the entire tree — every child context is cancelled simultaneously, every HTTP request tied to those contexts is aborted.

###### A3. How ctx attached to an HTTP request
(+) Go's standard library `http.NewRequestWithContext` binds a context to an HTTP request:
```
req, _ := http.NewRequestWithContext(ctx, "POST", url, body)`
resp, err := client.Do(req)
```
==> Internally, client.Do(req) starts a goroutine watching 2 things:
    1. Did the server respond?
    2. Did `ctx.Done()` closes

Whichever fires first wins. If ctx.Done() fires first, the TCP connection is torn down and an error is returned immediately. The goroutine exits. No leak.

```
func handler(ctx context.Context, req events.LambdaFunctionURLRequest) (...) {
    // ctx here already has deadline = Lambda timeout
    // use this ctx, not context.Background()
}
```

###### A4. When is cfg needed and when is it not
(+) If we are using Go's standard connector (like with RDS) we dont need cfg, if we are using AWS SDK then we need as SDK is connecting to AWS.

``` Standard's library for RDS
connector := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s", RDSUsername, RDSPassword, DBDomain, DBName)
db, err := sql.Open("mysql", connector)
```

``` AWS SDK for Secret Manager
cfg, err := config.LoadDefaultConfig(ctx)
client := secretsmanager.NewFromConfig(cfg)
result, err := client.GetSecretValue(ctx, ...)
```

==> ctx and cfg are only needed when you are calling the AWS SDK.