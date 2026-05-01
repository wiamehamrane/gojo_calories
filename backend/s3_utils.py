import os
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
import uuid

def get_s3_client():
    return boto3.client(
        's3',
        aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
        region_name=os.getenv('AWS_REGION', 'us-east-1')
    )

def upload_image_to_s3(file_bytes: bytes, content_type: str) -> str:
    bucket = os.getenv('AWS_BUCKET_NAME')
    file_name = f"food_logs_{uuid.uuid4()}.jpg"
    
    if not bucket:
        # Fallback to local file system
        os.makedirs("uploads", exist_ok=True)
        with open(f"uploads/{file_name}", "wb") as f:
            f.write(file_bytes)
        # Use a relative path that the client can prefix with its current base URL
        return f"/uploads/{file_name}"
        
    s3 = get_s3_client()
    
    try:
        s3.put_object(
            Bucket=bucket,
            Key=file_name,
            Body=file_bytes,
            ContentType=content_type
        )
        url = f"https://{bucket}.s3.{os.getenv('AWS_REGION', 'us-east-1')}.amazonaws.com/{file_name}"
        return url
    except (NoCredentialsError, ClientError) as e:
        print(f"S3 Upload failed: {e}")
        return None
