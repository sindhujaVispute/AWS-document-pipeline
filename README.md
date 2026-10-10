# AWS Document Pipeline (Serverless AI on AWS)

An event-driven, serverless pipeline that automatically processes PDF uploads, extracts text, generates AI summaries, and stores metadata in DynamoDB. 

This project was built to demonstrate production-grade AWS architecture, Infrastructure as Code (IaC), IAM least-privilege security, and comprehensive observability—all running within the AWS Free Tier.

## Architecture

```mermaid
graph TD
    User([User/App]) -->|1. Upload PDF| S3[Amazon S3]
    S3 -->|2. Event Trigger| Lambda[AWS Lambda]
    Lambda -->|3. Fetch API Key| SSM[AWS SSM Parameter Store]
    Lambda -->|4. Extract Text| PDF[PDF Parser]
    Lambda -->|5. Summarize| AI[Groq AI API]
    Lambda -->|6. Store Metadata| DDB[Amazon DynamoDB]
    Lambda -->|7. Push Custom Metrics| CW[Amazon CloudWatch]
    CW -->|8. Alarm Trigger| SNS[Amazon SNS]
    SNS -->|9. Email Alert| Admin([Engineer])

Key Features
100% Infrastructure as Code: Entirely provisioned via Terraform. No manual clicking in the AWS Console.

Serverless & Event-Driven: Automatically scales from 0 to thousands of requests. Zero servers to manage.

Secure by Design: Uses AWS SSM Parameter Store (SecureString) for API keys and enforces strict IAM Least-Privilege roles. No hardcoded secrets.

Full Observability: Custom CloudWatch metrics (DocumentsProcessed, ProcessingErrors), a CloudWatch Dashboard, and SNS email alerts on failure.

Cost-Optimized: Utilizes DynamoDB On-Demand capacity and AWS Free Tier limits to keep operational costs at $0.

Tech Stack
Category	Technologies Used
Cloud Provider	AWS (S3, Lambda, DynamoDB, SSM, CloudWatch, SNS, IAM)
Infrastructure as Code	Terraform
Compute	Python 3.12 (AWS Lambda)
AI Integration	Groq API (openai/gpt-oss-20b)
Libraries	boto3, pypdf, urllib3
CI/CD	GitHub Actions (OIDC Authentication) (Currently paused)

Deployment Guide
Prerequisites
AWS CLI configured with admin credentials (aws configure)

Terraform installed (v1.5+)

Python 3.12+ installed

A free API key from Groq

1. Clone the Repository
bash
git clone https://github.com/sindhujaVispute/AWS-document-pipeline.git
cd AWS-document-pipeline
2. Store Your AI API Key Securely
Store your Groq API key in AWS SSM Parameter Store:

bash
aws ssm put-parameter --name "/doc-pipeline/ai-api-key" --value "YOUR_GROQ_API_KEY" --type "SecureString" --region us-east-1
3. Build the Lambda Package
AWS Lambda requires a zip file containing your code and its dependencies (pypdf). Run the build script:

powershell
# Windows (PowerShell)
.\build.ps1
4. Deploy Infrastructure
Navigate to the Terraform directory and deploy:

bash
cd terraform
terraform init
terraform apply
# Type 'yes' to confirm

5. Confirm SNS Alerts
Terraform creates an SNS topic for error alerts. Check the email address you configured in terraform/observability.tf and click the "Confirm Subscription" link.

Testing the Pipeline
Navigate to your S3 bucket in the AWS Console (doc-pipeline-uploads-sindhuja-2026).

Upload any PDF document.

Wait ~5 seconds. The Lambda will trigger automatically.

Verify the result:

Go to DynamoDB → DocumentMetadata table → Explore items. You will see a new record with the AI-generated summary.

Go to CloudWatch → Log groups → /aws/lambda/doc-pipeline-processor to see the processing logs.

Go to CloudWatch → Dashboards → doc-pipeline-dashboard to view invocation metrics.

Future Enhancements
□ Frontend UI: Add a lightweight React or S3-hosted static frontend for users to upload and view documents.
□ Document Chunking: Implement text chunking to summarize PDFs larger than the LLM's token limit.

Author
Sindhuja Vispute
GitHub: @sindhujaVispute
