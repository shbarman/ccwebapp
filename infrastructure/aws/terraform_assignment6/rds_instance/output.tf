output "rds_endpoint" {
  value = "${aws_db_instance.rds_instance.endpoint}"

}

output "dynamodb_table" {
  value = "${aws_dynamodb_table.csye6225.name}"

}