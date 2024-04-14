output "aws_kms_key_arn" {
  value = aws_kms_key.primary_cmk.arn
}

output "aws_kms_key_arn_us_west_2" {
  value = aws_kms_replica_key.replica_us_west_2.arn
}

output "aws_kms_key_arn_us_east_2" {
  value = aws_kms_replica_key.replica_us_east_2.arn
}