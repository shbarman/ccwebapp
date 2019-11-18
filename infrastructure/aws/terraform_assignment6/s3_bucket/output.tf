output "s3_bucketId" {
  value = "${aws_s3_bucket.bucket.id}"
}
output "s3_bucketArn" {
  value = "${aws_s3_bucket.bucket.arn}"
}

output "s3_bucketName"{
  value = "${aws_s3_bucket.bucket}"
}