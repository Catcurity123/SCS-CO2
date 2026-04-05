resource "aws_s3_bucket" "source" {
  bucket        = "lab02-source-${random_id.suffix.hex}-test"
  force_destroy = true
}

resource "aws_s3_bucket" "destination" {
  bucket        = "lab02-dest-${random_id.suffix.hex}-test"
  force_destroy = true
}

