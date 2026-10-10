import boto3
import os
import json
import uuid
import urllib3
import datetime
from pypdf import PdfReader
from io import BytesIO

# Initialize AWS clients (outside handler = reused between warm invocations)
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
ssm_client = boto3.client('ssm')
cloudwatch = boto3.client('cloudwatch')
http = urllib3.PoolManager()

# Environment variables (set by Terraform)
TABLE_NAME = os.environ['TABLE_NAME']
SSM_PARAMETER_NAME = os.environ['SSM_PARAMETER_NAME']

# Cache the API key so we don't call SSM on every warm invocation
_cached_api_key = None


def get_api_key():
    """Fetch API key from SSM Parameter Store, with caching."""
    global _cached_api_key
    if _cached_api_key is None:
        response = ssm_client.get_parameter(
            Name=SSM_PARAMETER_NAME,
            WithDecryption=True
        )
        _cached_api_key = response['Parameter']['Value']
    return _cached_api_key


def extract_text_from_pdf(bucket, key):
    """Download the PDF from S3 and extract its text."""
    response = s3_client.get_object(Bucket=bucket, Key=key)
    pdf_bytes = response['Body'].read()
    reader = PdfReader(BytesIO(pdf_bytes))
    
    text = ""
    for page in reader.pages:
        text += page.extract_text() or ""
    return text


def summarize_with_ai(text):
    """Send text to Groq API and get a summary."""
    api_key = get_api_key()
    
    # Truncate to avoid hitting token limits on the free tier
    truncated_text = text[:3000]
    
    payload = {
        "model": "openai/gpt-oss-20b",
        "messages": [
            {
                "role": "system",
                "content": "You are a professional document summarizer. Summarize documents in 3 concise sentences."
            },
            {
                "role": "user",
                "content": f"Summarize this document:\n\n{truncated_text}"
            }
        ],
        "temperature": 0.3,
        "max_tokens": 200
    }
    
    response = http.request(
        'POST',
        'https://api.groq.com/openai/v1/chat/completions',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        },
        body=json.dumps(payload).encode('utf-8'),
        timeout=30.0
    )
    
    if response.status != 200:
        raise Exception(f"AI API returned {response.status}: {response.data.decode('utf-8')}")
    
    result = json.loads(response.data.decode('utf-8'))
    return result['choices'][0]['message']['content'].strip()


def push_metric(metric_name, value, unit='Count'):
    """Push a custom metric to CloudWatch."""
    cloudwatch.put_metric_data(
        Namespace='DocPipeline',
        MetricData=[{
            'MetricName': metric_name,
            'Value': value,
            'Unit': unit,
            'Timestamp': datetime.datetime.utcnow()
        }]
    )


def lambda_handler(event, context):
    """Main entry point. Triggered by S3 upload event."""
    start_time = datetime.datetime.utcnow()
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        print(f"Processing s3://{bucket}/{key}")
        
        try:
            # Step 1: Extract text
            text = extract_text_from_pdf(bucket, key)
            if not text.strip():
                print(f"No text extracted from {key}, skipping.")
                continue
            
            # Step 2: Summarize with AI
            summary = summarize_with_ai(text)
            
            # Step 3: Save to DynamoDB
            table = dynamodb.Table(TABLE_NAME)
            doc_id = str(uuid.uuid4())
            table.put_item(Item={
                'documentId': doc_id,
                'bucket': bucket,
                'key': key,
                'summary': summary,
                'textLength': len(text),
                'processedAt': datetime.datetime.utcnow().isoformat()
            })
            
            # Step 4: Push metrics
            duration = (datetime.datetime.utcnow() - start_time).total_seconds()
            push_metric('DocumentsProcessed', 1)
            push_metric('ProcessingDuration', duration, unit='Seconds')
            
            print(f"Successfully processed {key}. Summary: {summary[:100]}...")
            
        except Exception as e:
            print(f"ERROR processing {key}: {str(e)}")
            push_metric('ProcessingErrors', 1)
            raise
    
    return {'statusCode': 200, 'body': json.dumps('Processing complete')}