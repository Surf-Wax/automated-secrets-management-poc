"""
Demonstrates Vault's automatic credential rotation using the static role.
This script shows how credentials are automatically rotated and stay valid.
"""

import hvac      # HashiCorp Vault client library
import boto3     # AWS SDK for Python
import time
from botocore.exceptions import ClientError

def get_credentials_from_vault(vault_client):
    """
    Retrieve AWS credentials from Vault.
    
    Args:
        vault_client: Initialized hvac (Vault) client
        
    Returns:
        tuple: (access_key, secret_key) or (None, None) if retrieval fails
    """
    try:
        # Read credentials from Vault's AWS secret backend
        # Path matches the static role name configured in Terraform
        response = vault_client.read("aws/static-creds/app-credentials")
        if not response or 'data' not in response:
            print("Failed to get credentials from Vault")
            return None, None
        
        return (
            response['data'].get('access_key'),
            response['data'].get('secret_key')
        )
    except Exception as e:
        print(f"Error getting credentials from Vault: {e}")
        return None, None

def test_aws_auth(access_key, secret_key) -> bool:
    """
    Test AWS authentication by attempting to list EC2 instances.
    
    Args:
        access_key: AWS access key ID
        secret_key: AWS secret access key
        
    Returns:
        bool: True if authentication successful, False otherwise
    """
    try:
        if not access_key or not secret_key:
            print("Missing credentials")
            return False

        # Create boto3 session with provided credentials
        session = boto3.Session(
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name='us-east-1'
        )
        
        # Create EC2 client pointing to LocalStack
        ec2 = session.client(
            'ec2',
            endpoint_url='http://localhost:4566',  # LocalStack endpoint
            region_name='us-east-1'
        )
        
        # Test authentication by listing EC2 instances
        response = ec2.describe_instances()
        print(f"Found {len(response['Reservations'])} EC2 instances")
        return True
        
    except ClientError as e:
        print(f"Authentication failed: {e.response['Error']['Message']}")
        return False

def demonstrate_rotation():
    """
    Demonstrates the full credential rotation workflow:
    1. Get initial credentials from Vault
    2. Test AWS authentication
    3. Wait for rotation period
    4. Get new credentials
    5. Test authentication with new credentials
    """
    # Initialize Vault client
    vault_client = hvac.Client(
        url='http://127.0.0.1:8200',
        token='root'  # Development root token
    )
    
    print("\n=== Starting Secure Credential Rotation Demo ===\n")
    
    try:
        # Get initial credentials from Vault
        print("1. Getting initial credentials from Vault...")
        access_key, secret_key = get_credentials_from_vault(vault_client)
        
        # Test initial authentication
        print("2. Testing initial AWS authentication...")
        if test_aws_auth(access_key, secret_key):
            print("✓ Successfully authenticated with AWS")
        else:
            print("✗ AWS authentication failed")
            return
            
        # Wait for rotation period (configured as 61 seconds in Terraform)
        print("\n3. Waiting for credential rotation period...")
        time.sleep(65)  # Wait slightly longer than rotation period
        
        # Get new credentials after rotation
        print("\n4. Getting new credentials after rotation...")
        new_access_key, new_secret_key = get_credentials_from_vault(vault_client)
        
        # Test authentication with new credentials
        print("5. Testing AWS authentication with new credentials...")
        if test_aws_auth(new_access_key, new_secret_key):
            print("✓ Successfully authenticated with new credentials")
        else:
            print("✗ Authentication failed after rotation")
            
    except Exception as e:
        print(f"Error during demonstration: {str(e)}")
    
    print("\n=== Rotation Demonstration Complete ===")

if __name__ == "__main__":
    demonstrate_rotation()