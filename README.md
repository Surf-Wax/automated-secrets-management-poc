# Automated AWS Credential Rotation with HashiCorp Vault 

This proof of concept demonstrates automated AWS credential rotation using HashiCorp Vault, as discussed in the research paper "Automated Secrets Management in IaC". It showcases secure credential management practices by automatically rotating AWS IAM user credentials without application interruption.

## Architecture Overview

The demonstration uses:

- **HashiCorp Vault**: For secure credential storage and automated rotation
- **LocalStack**: To simulate AWS services locally
- **Terraform**: To provision and configure the infrastructure
- **Python**: To demonstrate the credential rotation in action

The setup creates two IAM users:

1. `application-service-user`: A service account whose credentials are rotated
2. `vault-credentials-manager`: A privileged account that Vault uses to perform the rotation

## Prerequisites

- Docker and Docker Compose (20.10+)
- Python 3.8+
- Terraform 1.0+
- Git

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/Surf_Wax/automated-secrets-management-poc.git
cd automated-secrets-management-poc
```

2. Create and activate virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\activate on Windows
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Start the infrastructure:
```bash
docker-compose up -d
```

5. Initialize and apply Terraform configuration:
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

6. Run the demonstration:
```bash
python src/demo.py
```

## Project Structure

```plaintext
.
├── src/
│   ├── demo.py              # Python script demonstrating credential rotation
├── terraform/
│   ├── .terraform/          # Terraform installation files (auto-generated)
│   ├── main.tf              # Main Terraform configuration
│   ├── terraform.tfstate    # Terraform state file 
│   └── terraform.lock.hcl   # Terraform dependency lock file
├── venv/                    # Python virtual environment (if used)
├── volume/                  # LocalStack persistent volume
├── .gitignore               # Git ignore file
├── docker-compose.yml       # Local infrastructure configuration
├── README.md                # Project documentation
└── requirements.txt         # Python dependencies
```

## How It Works

### Infrastructure Setup (main.tf)

The Terraform configuration:
1. Creates an application user with permissions to list EC2 instances
2. Creates a Vault manager user with permissions to rotate credentials
3. Configures Vault's AWS secrets engine for credential rotation
4. Creates a test EC2 instance to verify credential functionality

### Credential Rotation Flow

1. Vault is configured to rotate the application user's credentials every 61 seconds
2. When rotation occurs:
   - Vault uses the vault-manager credentials to create new access keys
   - Applications retrieve current credentials from Vault
   - Vault automatically cleans up old credentials

### Demonstration (demo.py)

The Python script demonstrates:
1. Retrieving credentials from Vault
2. Using credentials to authenticate with AWS
3. Automatic credential rotation
4. Continuous application functionality during rotation

## Running the Demo

1. Start the infrastructure:
```bash
docker-compose up -d
```

2. Initialize and apply Terraform configuration:
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

3. Run the example implementation:
```bash
python src/demo.py
```

Expected output:
```
=== Starting Secure Credential Rotation Demo ===

1. Getting initial credentials from Vault...
2. Testing initial AWS authentication...
Found 1 EC2 instances
✓ Successfully authenticated with AWS

3. Waiting for credential rotation period...

4. Getting new credentials after rotation...
5. Testing AWS authentication with new credentials...
Found 1 EC2 instances
✓ Successfully authenticated with new credentials

=== Rotation Demonstration Complete ===
```

## Security Considerations

This proof of concept demonstrates several security best practices:
- Automated credential rotation
- Principle of least privilege
- Separation of duties between application and management credentials
- Centralized secret management

However, for production use, consider:
- Using AWS IAM roles instead of static credentials for Vault
- Implementing proper Vault authentication methods
- Enabling audit logging
- Using proper TLS certificates
- Implementing proper backup and recovery procedures

## Production Implementation

For production environments:
1. Replace LocalStack with actual AWS services
2. Configure proper Vault authentication
3. Use IAM roles instead of the vault-manager user
4. Implement proper monitoring and alerting
5. Consider using AWS Secrets Manager or AWS Parameter Store as alternatives

## Further Reading

- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Citation

If you use this proof of concept in your research, please cite:
```
Thorpe, B. (2024). Automated Secrets Management in IaC. 
University of Arizona, College of Applied Science & Technology.
```

## Acknowledgments

This proof of concept was developed as part of the CYBV 498 Senior Capstone course at the University of Arizona, under the supervision of Professor Wagner.