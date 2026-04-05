package main

import (
	"database/sql"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	lambda.Start(goHandler)
}

func goHandler(events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
	result := ""
	RDSConnected := false

	//Build Connector
	RDSUsername := ""
	RDSPassword := ""
	DBDomain := ""
	DBName := ""
	connector := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s", RDSUsername, RDSPassword, DBDomain, DBName)

	//Use connector to open DB
	db, err := sql.Open("mysql", connector)
	if err != nil {
		result += fmt.Sprintf("RDS open FAILED: %s\n", err)
		return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
	}
	defer db.Close() //Close the connection after finished, releasing memory after retuns

	//Test DB Connectivity
	if err := db.Ping(); err != nil {
		result += fmt.Sprintf("RDS connection check FAILED: %s\n", err)
		return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
	}
	RDSConnected = true
	result += "RDS connectivity OK\n"

	//Create Table
	if RDSConnected {
		_, err = db.Exec(`
        CREATE TABLE IF NOT EXISTS users (
            id   INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            age  INT NOT NULL
        )
    	`)

		if err != nil {
			result += fmt.Sprintf("Create table FAILED: %s\n", err)
			return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
		}
		result += "Table ready\n"
	}

	//Insert Test user and select user
	_, err = db.Exec("INSERT INTO users (name, age) VALUES (?, ?)", "josh", 22)
	if err != nil {
		result += fmt.Sprintf("Insert FAILED: %s\n", err)
		return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
	}
	result += "Inserted user josh age 22\n"

	rows, err := db.Query("SELECT id, name, age FROM users")
	if err != nil {
		result += fmt.Sprintf("Query FAILED: %s\n", err)
		return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
	}
	defer rows.Close() //Releash cursor to pool

	//Return result
	return events.LambdaFunctionURLResponse{Body: result, StatusCode: 200}, nil
}
