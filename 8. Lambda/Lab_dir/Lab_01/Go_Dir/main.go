package main

import (
    "fmt"
    "net"
    "net/http"
    "os"
    "time"

    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
    _ "github.com/go-sql-driver/mysql"
)
///GOOS=linux GOARCH=amd64 go build -o bootstrap main.go


func main(){
	lambda.Start(goHandler)
}

const testUrl = "https://vnexpress.net"

func goHandler(request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error){
	result := ""

	/// ---- 1. Test Public Connectivity ----
	resp, err := http.Get(testUrl)
	if err != nil {
        result += fmt.Sprintf("Internet check FAILED: %s\n", err)
    } else {
        resp.Body.Close()
        result += fmt.Sprintf("Internet check OK: status %d\n", resp.StatusCode)
    }

    /// ---- 2. Test Private Connectivity (VPC internal) ----
    dbHost := os.Getenv("DB_HOST")
    if dbHost == "" {
        result += "Private check SKIPPED: DB_HOST env var not set\n"
    } else {
        addr := dbHost + ":3306"
        conn, err := net.DialTimeout("tcp", addr, 3*time.Second)
        if err != nil {
            result += fmt.Sprintf("Private check FAILED (%s): %s\n", addr, err)
        } else {
            conn.Close()
            result += fmt.Sprintf("Private check OK: TCP connection to %s succeeded\n", addr)
        }
    }

    return events.LambdaFunctionURLResponse{Body: result, StatusCode: 200}, nil
}