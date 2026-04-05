package main

import (
    "fmt"
    "net/http"

    "github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-lambda-go/lambda"
    _ "github.com/go-sql-driver/mysql"
)

func main(){
	lambda.Start(goHandler)
}

const testUrl = "https://vnexpress.net"

func goHandler(request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error){
	result := ""

	resp, err := http.Get(testUrl)
	if err != nil{
		result += fmt.Sprintf("Internet check FAILED: %s\n", err)
		return events.LambdaFunctionURLResponse{Body: result, StatusCode: resp.StatusCode}, err
	} else {
		resp.Body.Close()
		result += fmt.Sprintf("Internet check OK: status %d\n", resp.StatusCode)
	}

	return events.LambdaFunctionURLResponse{Body: result, StatusCode: 200}, nil
}
