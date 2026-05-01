import os
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
import uuid
import logging

logger = logging.getLogger(__name__)

def get_s3_client():
    # Use environment variables if provided, otherwise let boto3 find credentials (e.g. ECS Task Role)
    access_key = os.getenv('AWS_ACCESS_KEY_ID')
    secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')
    region = os.getenv('AWS_REGION', 'us-east-1')
    
    kwargs = {'region_name': region}
    if access_key and secret_key:
        kwargs['aws_access_key_id'] = access_key
        kwargs['aws_secret_access_key'] = secret_key
    
    return boto3.client('s3', **kwargs)

def upload_image_to_s3(file_bytes: bytes, content_type: str) -> str:
    bucket = os.getenv('AWS_BUCKET_NAME')
    file_name = f"food_logs_{uuid.uuid4()}.jpg"
    
    if not bucket:
        logger.warning("AWS_BUCKET_NAME not set, falling back to local storage.")
        os.makedirs("uploads", exist_ok=True)
        with open(f"uploads/{file_name}", "wb") as f:
            f.write(file_bytes)
        return f"/uploads/{file_name}"
        
    s3 = get_s3_client()
    
    try:
        logger.info(f"Uploading image to S3 bucket: {bucket}, key: {file_name}")
        s3.put_object(
            Bucket=bucket,
            Key=file_name,
            Body=file_bytes,
            ContentType=content_type
        )
        
        # Generate a pre-signed URL since the bucket is private
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': file_name},
            ExpiresIn=604800 # 7 days
        )
        logger.info(f"S3 upload successful. Generated pre-signed URL: {url}")
        return url
    except (NoCredentialsError, ClientError) as e:
        logger.error(f"S3 Upload failed: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error during S3 upload: {e}")
        return None
