#### Compile Cheatsheet
(+) `go mod init <project_name>`: init a module creating a go.mod
(+) `go get <package>`: get a package and add to go.mod
(+) `go mod tidy`: scan the source file for package referneces and add to go.mod
(+) `go build .`: to build a binary
(+) `go run .`: to run the project without build
(+) `GOOS=linux GOARCH=amd64 go build -o bootstrap main.go`: build binary for linux

