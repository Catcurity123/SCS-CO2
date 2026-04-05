package main

import (
    "database/sql"
    "encoding/json"
    "fmt"
    "net/http"
    "os"

    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/service/secretsmanager"
    _ "github.com/go-sql-driver/mysql"
    "context"
)

type DBSecret struct {
    Username string `json:"username"`
    Password string `json:"password"`
    Host     string `json:"host"`
    DBName   string `json:"dbname"`
}

func getSecret(ctx context.Context) (*DBSecret, error) {
    cfg, err := config.LoadDefaultConfig(ctx)
    if err != nil {
        return nil, err
    }

    client := secretsmanager.NewFromConfig(cfg)
    result, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
        SecretId: aws.String(os.Getenv("SECRET_ARN")),
    })
    if err != nil {
        return nil, err
    }

    var secret DBSecret
    if err := json.Unmarshal([]byte(*result.SecretString), &secret); err != nil {
        return nil, err
    }

    return &secret, nil
}

func goHandler(request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
    ctx := context.Background()
    result := ""

    // --- 1. Internet check ---
    resp, err := http.Get("https://vnexpress.net")
    if err != nil {
        result += fmt.Sprintf("Internet check FAILED: %s\n", err)
    } else {
        resp.Body.Close()
        result += fmt.Sprintf("Internet check OK: status %d\n", resp.StatusCode)
    }

    // --- 2. Fetch credentials from Secrets Manager ---
    secret, err := getSecret(ctx)
    if err != nil {
        result += fmt.Sprintf("Secrets Manager FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    result += "Secrets Manager OK\n"

    // --- 3. Connect to RDS ---
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

    if err := db.Ping(); err != nil {
        result += fmt.Sprintf("RDS ping FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    result += "RDS connectivity OK\n"

    // --- 4. Create table, insert, query ---
    db.Exec(`CREATE TABLE IF NOT EXISTS users (
        id   INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        age  INT NOT NULL
    )`)

    db.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "josh", 22)

    rows, _ := db.Query("SELECT id, name, age FROM users")
    defer rows.Close()
    result += "\n--- Users in DB ---\n"
    for rows.Next() {
        var id int
        var name string
        var age int
        rows.Scan(&id, &name, &age)
        result += fmt.Sprintf("id=%d name=%s age=%d\n", id, name, age)
    }

    return events.LambdaFunctionURLResponse{Body: result, StatusCode: 200}, nil
}

func main() {
    lambda.Start(goHandler)
}