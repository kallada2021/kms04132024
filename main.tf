provider "aws" {
    region = "us-east-1" # Or your relevant region
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

resource "aws_kms_key" "primary_cmk" {
    multi_region = true
    description             = "Primary CMK"
    deletion_window_in_days = 7
    enable_key_rotation     = true

    tags = {
        Name = "my-primary-cmk7"
    }
}

locals {
  primary_cmk_arn = aws_kms_key.primary_cmk.arn
  primary_cmk_id  = aws_kms_key.primary_cmk.key_id 
}


resource "aws_kms_replica_key" "replica_us_west_2" {
  provider      = aws.us-west-2
  primary_key_arn = local.primary_cmk_arn


  tags = {
    Name = "my-replica-cmk-us-west-2" 
  }
}

resource "aws_kms_alias" "a" {
  provider = aws.us-west-2
  name          = "alias/my-key-alias-uswest2"
  target_key_id = aws_kms_replica_key.replica_us_west_2.key_id
}

resource "aws_kms_replica_key" "replica_us_east_2" {
  provider      = aws.us-east-2
  primary_key_arn = local.primary_cmk_arn
  description     = "Replica of ${local.primary_cmk_id} in us-east-2"

  tags = {
    Name = "my-replica-cmk-us-east-2" 
  }
}

resource "aws_kms_alias" "b" {
  provider = aws.us-east-2
  name          = "alias/my-key-alias-useast2"
  target_key_id = aws_kms_replica_key.replica_us_east_2.key_id
}

resource "aws_kms_alias" "primaryalias" {
    name          = "alias/my-primary-cmk7"
    target_key_id = aws_kms_key.primary_cmk.key_id
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

# resource "local_file" "kms_key_output" {
#   content = jsonencode({
#     arn         = aws_kms_key.primary.arn
#     key_id      = aws_kms_key.primary.key_id
#     # Add other attributes as needed 
#   })
#   filename = "kms_key_details.txt" 
# }

# resource "null_resource" "run_python_script" {
#   # This resource will execute our script
#   triggers = {
#     # Trigger when the file content changes
#     file_md5 = local_file.kms_key_output.content_md5 
#   }

#   provisioner "local-exec" {
#     command = "python create_replicas.py" 
#   }

#   depends_on = [local_file.kms_key_output ]
# }