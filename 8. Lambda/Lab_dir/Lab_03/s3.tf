resource "aws_s3_bucket" "source" {
  bucket        = "lab03-source-${random_id.suffix.hex}-test"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  bucket        = "lab03-dest-${random_id.suffix.hex}-test"
  force_destroy = true
}

