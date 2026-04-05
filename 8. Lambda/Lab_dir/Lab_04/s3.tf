resource "aws_s3_bucket" "source" {
  bucket        = "lab04-source-${random_id.suffix.hex}-test"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  bucket        = "lab04-dest-${random_id.suffix.hex}-test"
  force_destroy = true
}

