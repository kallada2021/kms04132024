import boto3
import json
import os

def get_cmk_arn():
    primary_cmk_arn = os.environ.get('PRIMARY_CMK_ARN')
    if not primary_cmk_arn:
        raise ValueError("PRIMARY_CMK_ARN not found in environment variables.")

    regions = ['us-west-2', 'us-east-2'] # Add your regions

    def create_replica_key(region):
        client = boto3.client('kms', region_name=region)
        response = client.create_key(
            Description='Replica of ' + primary_cmk_arn,
            Origin='AWS_KMS',
            KeySpec='SYMMETRIC_DEFAULT', 
            KeyUsage='ENCRYPT_DECRYPT',
            Policy='arn:aws:kms:::aws:servicepolicy/AWSKeyManagementServicePowerUser', # Adjust policy as needed
            Tags=[
                {'TagKey': 'Name', 'TagValue': 'my-replica-cmk'} 
            ]
        )
        return response['KeyMetadata']['Arn']

    for region in regions:
        replica_arn = create_replica_key(region)
        print(f"Replica Key created in {region}: {replica_arn}")

    result = {"cmk_arn": primary_cmk_arn}
    print(json.dumps(result))

if __name__ == '__main__':
    get_cmk_arn()