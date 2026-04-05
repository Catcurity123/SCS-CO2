package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

/// GOOS=linux GOARCH=amd64 go build -o bootstrap main.go

var s3Client *s3.Client

func init() { //Runs before main
	ctx := context.Background() //context represent the lifetime and control plane of an AWS operation -> how long a process can run, who can cancel it, metadata
	cfg, err := config.LoadDefaultConfig(ctx) //Configure lambda to use the login profile
	if err != nil {
		panic(fmt.Sprintf("failed to load AWS config: %v", err))
	}
	s3Client = s3.NewFromConfig(cfg)

}

func main() { //Runs when function is invoke
	lambda.Start(goHandler) //Passing a function as a parameter
}

func goHandler(ctx context.Context, s3Event events.S3Event) error {
	destBucket := os.Getenv("DEST_BUCKET") //Get dest's ARN through environment
	if destBucket == "" {
		return fmt.Errorf("DEST_BUCKET environment variable is not set")
	}

	for _, record := range s3Event.Records { //An event may have multiple action, record is to hold them
		srcBucket := record.S3.Bucket.Name //Get the source bucket from one record, my bucket
		key := record.S3.Object.Key //Key is a path to an s3 object, logs/2026/app.log

		// --- 1. Download from source bucket ---
		getOut, err := s3Client.GetObject(ctx, &s3.GetObjectInput{
			Bucket: aws.String(srcBucket),
			Key:    aws.String(key),
		})
		//S3 Object contains metadata and body
		//Metadata consists of content-type, content-length, and other metadata
		//Body is the actual file data
		if err != nil {
			return fmt.Errorf("GetObject failed for s3://%s/%s: %w", srcBucket, key, err)
		}

		defer getOut.Body.Close()

		// --- 2. Upload to destination bucket (same key) ---
		_, err = s3Client.PutObject(ctx, &s3.PutObjectInput{
			Bucket:        aws.String(destBucket),
			Key:           aws.String(key),
			Body:          getOut.Body,          //getOut.body ==> file size 500MB would not be downloaded to the memory and send, but it will send chunk by chunk of 8KB
			ContentType:   getOut.ContentType,   //type: io.ReadCloser, then depend on the content type, the file type (csv, img, md) the client will interpret the file
			ContentLength: getOut.ContentLength, //Known size prevents chunked transfer encoding + trailing checksum headers (avoids 501 NotImplemented)
		})
		if err != nil {
			return fmt.Errorf("PutObject failed for s3://%s/%s: %w", destBucket, key, err)
		}

		fmt.Printf("Copied s3://%s/%s -> s3://%s/%s\n", srcBucket, key, destBucket, key)
	}

	return nil
}
