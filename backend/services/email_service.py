import os
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timedelta
import jwt
import logging

logger = logging.getLogger(__name__)

# Re-use secret key from security for JWT token signing
from security import SECRET_KEY, ALGORITHM

SES_SENDER_EMAIL = os.getenv("SES_SENDER_EMAIL", "noreply@gojocalories.com")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

def get_ses_client():
    return boto3.client(
        'ses',
        region_name=AWS_REGION,
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY")
    )

def send_email(to_email: str, subject: str, html_body: str):
    """Sends an email using AWS SES."""
    client = get_ses_client()
    try:
        response = client.send_email(
            Destination={'ToAddresses': [to_email]},
            Message={
                'Body': {
                    'Html': {'Charset': "UTF-8", 'Data': html_body},
                },
                'Subject': {'Charset': "UTF-8", 'Data': subject},
            },
            Source=SES_SENDER_EMAIL,
        )
        return True
    except ClientError as e:
        logger.error(f"Failed to send email to {to_email}: {e.response['Error']['Message']}")
        return False
