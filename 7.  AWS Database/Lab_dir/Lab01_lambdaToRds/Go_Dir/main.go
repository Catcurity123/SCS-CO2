package main

import (
    "database/sql"
    "fmt"
    "net/http"
	"os"

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

	/// ---- 2. Test RDS connector ----
	dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/%s",
    "testdbuser",
    "testpassword",
    os.Getenv("DB_HOST"),  
    "testdb",
    )

	db, err := sql.Open("mysql", dsn)
    if err != nil {
        result += fmt.Sprintf("RDS open FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    defer db.Close()

	/// ---- 3. Test RDS connectivity ----
	if err := db.Ping(); err != nil {
        result += fmt.Sprintf("RDS ping FAILED: %s\n", err)
        return events.LambdaFunctionURLResponse{Body: result, StatusCode: 500}, nil
    }
    result += "RDS connectivity OK\n"

	/// ---- 4. Create Table ----
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

    // --- 4. Insert user ---
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