provider "aws" {
    region = "us-east-1" # Or your relevant region
}

resource "aws_kms_key" "primary" {
    multi_region = true
    description             = "Primary CMK"
    deletion_window_in_days = 10
    enable_key_rotation     = true

    tags = {
        Name = "my-primary-cmk5"
    }
}

resource "aws_kms_alias" "primaryalias" {
    name          = "alias/my-primary-cmk5"
    target_key_id = aws_kms_key.primary.key_id
}

# resource "aws_kms_key" "primarypolicy" {
#     // existing code

#     policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Id": "key-policy",
#     "Statement": [
#         {
#             "Sid": "AllowAdministrators",
#             "Effect": "Allow",
#             "Principal": {
#                 "AWS": "arn:aws:iam::381485378882:role/admin-role"
#             },
#             "Action": [
#                 "kms:Encrypt",
#                 "kms:Decrypt",
#                 "kms:ReEncrypt*",
#                 "kms:GenerateDataKey*",
#                 "kms:DescribeKey"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF
# }

# resource "aws_kms_key_policy" "primary" {
#     key_id  = aws_kms_key.primary.key_id
#     policy  = aws_kms_key.primarypolicy.policy
# }

resource "local_file" "kms_key_output" {
  content = jsonencode({
    arn         = aws_kms_key.primary.arn
    key_id      = aws_kms_key.primary.key_id
    # Add other attributes as needed 
  })
  filename = "kms_key_details.txt" 
}

resource "null_resource" "run_python_script" {
  # This resource will execute our script
  triggers = {
    # Trigger when the file content changes
    file_md5 = local_file.kms_key_output.content_md5 
  }

  provisioner "local-exec" {
    command = "python create_replicas.py" 
  }

  depends_on = [local_file.kms_key_output ]
}