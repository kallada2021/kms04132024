import boto3
import json 


def read_arn_from_file(filename):
    """Reads the primary CMK ARN from a JSON file.

    Args:
        filename: kms_key_details.txt

    Returns:
        The primary CMK ARN.
    """

    with open(filename, 'r') as file:
        data = json.load(file)
        return data['arn']
    print(arn)

def create_replica_key(region, primary_cmk_arn):
    """Creates a replica KMS key in the specified region.

    Args:
        region: The AWS region where the replica will be created.
        primary_cmk_arn: The ARN of the primary KMS key.

    Returns:
        The ARN of the newly created replica KMS key.
    """

    client = boto3.client('kms', region_name=region)
    response = client.create_key(
        Description='Replica of ' + primary_cmk_arn,
        Origin='AWS_KMS',
        KeySpec='SYMMETRIC_DEFAULT', 
        KeyUsage='ENCRYPT_DECRYPT',
        # Policy='arn:aws:kms:::aws:servicepolicy/AWSKeyManagementServicePowerUser', # Adjust policy as needed
        Tags=[
            {'TagKey': 'Name', 'TagValue': 'my-replica-cmk'} 
        ]
    )

    key_id = response['KeyMetadata']['KeyId']
    print(f"Replica Key ID: {key_id}")

    # Add alias (assuming you want a consistent alias across replicas)
    alias_name = "alias/my-replica-cmk-alias" 
    client.create_alias(
        AliasName=alias_name,
        TargetKeyId=response['KeyMetadata']['KeyId'] 
    )

    # Enable rotation and schedule deletion
    client.enable_key_rotation(KeyId=key_id)
    client.schedule_key_deletion(KeyId=key_id, DeletionWindowInDays=7)

    return response['KeyMetadata']['Arn']

if __name__ == '__main__':
    filename = 'kms_key_details.txt'  # Adjust if your file has a different name
    primary_cmk_arn = read_arn_from_file(filename)
    print(f"Primary Key ARN: {primary_cmk_arn}")
    regions = ['us-west-2', 'us-east-2'] 

    for region in regions:
        replica_arn = create_replica_key(region, primary_cmk_arn)
        print(f"Replica Key created in {region}: {replica_arn}")
