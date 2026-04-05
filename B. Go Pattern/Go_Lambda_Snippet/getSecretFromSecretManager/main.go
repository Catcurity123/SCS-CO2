package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	lambda.Start(goHandler)
}

// Secret manager will return one long string, and our connector can not use just that string
// {"username":"admin","password":"MyP@ssword","host":"mydb.rds.amazonaws.com","dbname":"appdb"}

/* When we get the result from secret manager, it returns a *string, pointer to a string.
Then the we need to break that string to bytes for unmarshal to use, []byte(*result.SecretString)
Unmarshal then act as a parser, it looks at the tag 'json:"username"' and knows that it is the value for struct field Username
It then parse the value into Username. Hence why we need to use both the tagging and the unmarshal */

type DBSecret struct{
	Username string `json:"username"`
	Password string `json:"password"`
	Host string `json:"host"`
	DBName string `json:"dbname"`
}

//Init connection from SDK to AWS
func initConnection(ctx context.Context) (*secretsmanager.Client, error){
	//Create config struct for AWS SDK communication
	cfg, err := config.LoadDefaultConfig(ctx)
    if err != nil {
        return nil, err
    }
    client := secretsmanager.NewFromConfig(cfg) //Create a client to AWS SecretManager from the config
	return client, nil
}

//Get Secret from AWS Secret Manager
func getSecret(ctx context.Context) (*DBSecret, error) {
    client, err := initConnection(ctx)
	if err != nil {
		return nil, err
	}
	//Call GetSecretValue API using the client, attaching the context for HTTP request's lifecycle.
	//The call require the SecretId, so that it can get the correct secret
    result, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
        SecretId: aws.String(os.Getenv("SECRET_ARN")),
    })
    if err != nil {
        return nil, err
    }
	//Parse the secret value into the DBSecret struct using Unmarshal
    var secret DBSecret
    if err := json.Unmarshal([]byte(*result.SecretString), &secret); err != nil {
        return nil, err
    }
	//Return the secret
    return &secret, nil
}

func goHandler(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
    result := ""

    // --- 1. Fetch credentials from Secrets Manager ---
	//goHandler → getSecret → LoadDefaultConfig → GetSecretValue → http.Request
	//at each HTTP call, ctx.Done() is watched as a kill switch
    secret, err := getSecret(ctx) //Pass Lambda's context to the request
    if err != nil {
        result += fmt.Sprintf("Secrets Manager FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    result += "Secrets Manager OK\n"

    // --- 2. Connect to RDS ---
    dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s",
        secret.Username,
        secret.Password,
        secret.Host,
        secret.DBName,
    )
    db, err := sql.Open("mysql", dsn)
    if err != nil {
        result += fmt.Sprintf("RDS open FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    defer db.Close()

	// --- 3. Check connectivity to RDS ---
    if err := db.Ping(); err != nil {
        result += fmt.Sprintf("RDS ping FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    result += "RDS connectivity OK\n"
	return events.LambdaFunctionURLResponse{Body: result, StatusCode: 200}, nil
}