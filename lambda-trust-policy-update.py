import boto3
import json
import logging
import copy
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Extract role name from event
    role_name = event.get('role_name')
    if not role_name:
        logger.error("No role name provided in event")
        return {
            'statusCode': 400,
            'body': json.dumps('Role name is required')
        }
    
    iam_client = boto3.client('iam')
    
    try:
        logger.info(f"Starting trust policy update for role: {role_name}")
        
        # Retrieve existing trust policy
        try:
            current_policy = iam_client.get_role(RoleName=role_name)['Role']['AssumeRolePolicyDocument']
        except ClientError as e:
            logger.error(f"Failed to retrieve role policy: {e}")
            return {
                'statusCode': 404,
                'body': json.dumps(f'Role {role_name} not found')
            }
        
        # Deep copy to avoid modifying original
        updated_policy = copy.deepcopy(current_policy)
        
        # Dynamically extract Cognito statement
        cognito_statement = next(
            (stmt for stmt in current_policy['Statement'] 
             if "cognito-identity.amazonaws.com" in str(stmt.get('Principal', {}))), 
            None
        )
        
        # Validate and update policy
        if not cognito_statement:
            logger.warning(f"No Cognito statement found in role {role_name}")
            return {
                'statusCode': 400,
                'body': json.dumps('No Cognito statement found'),
                'role_processed': role_name
            }
        
        # Prepare return payload
        return {
            'statusCode': 200,
            'body': json.dumps('Trust policy analyzed successfully'),
            'role_name': role_name,
            'current_policy': current_policy,
            'cognito_statement': cognito_statement
        }
    
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing role: {str(e)}'),
            'role_name': role_name
        }
