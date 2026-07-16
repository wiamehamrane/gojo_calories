import os
import boto3
from botocore.exceptions import NoCredentialsError, ClientError
import uuid
import logging

logger = logging.getLogger(__name__)


class MediaUploadError(Exception):
    """Raised when durable media storage (S3) is unavailable."""


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


def _allow_local_fallback() -> bool:
    """Local /uploads is ephemeral on ECS — only allow it in explicit local/dev mode."""
    if os.getenv('ALLOW_LOCAL_UPLOADS', '').lower() in ('1', 'true', 'yes'):
        return True
    # No bucket configured ⇒ assume local development.
    return not bool(os.getenv('AWS_BUCKET_NAME'))


def _save_locally(file_bytes: bytes, file_name: str) -> str:
    """Helper to save file to local uploads directory (dev only)."""
    os.makedirs("uploads", exist_ok=True)
    file_path = os.path.join("uploads", file_name)
    with open(file_path, "wb") as f:
        f.write(file_bytes)
    logger.warning(
        "File saved locally at %s — this WILL disappear on container redeploy. "
        "Set AWS_BUCKET_NAME and fix S3 access for production.",
        file_path,
    )
    return f"/uploads/{file_name}"


def upload_image_to_s3(file_bytes: bytes, content_type: str) -> str:
    bucket = os.getenv('AWS_BUCKET_NAME')
    file_name = f"food_logs_{uuid.uuid4()}.jpg"

    if not bucket:
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name)
        raise MediaUploadError("AWS_BUCKET_NAME is not configured")

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
            ExpiresIn=604800  # 7 days
        )
        logger.info(f"S3 upload successful. Generated pre-signed URL: {url}")
        return url
    except (NoCredentialsError, ClientError) as e:
        logger.error(f"S3 Upload failed: {e}")
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name)
        raise MediaUploadError(f"S3 upload failed: {e}") from e
    except Exception as e:
        logger.error(f"Unexpected error during S3 upload: {e}")
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name)
        raise MediaUploadError(f"S3 upload failed: {e}") from e


def upload_image_to_s3_key(file_bytes: bytes, content_type: str, prefix: str = "") -> str:
    """Upload an image and return its stable S3 key (NOT a presigned URL).

    Store the key in the database and call presign_s3_key() on every read,
    so image links never expire. Falls back to a local /uploads path only
    when ALLOW_LOCAL_UPLOADS=true or AWS_BUCKET_NAME is unset (local/dev).
    """
    bucket = os.getenv('AWS_BUCKET_NAME')
    file_name = f"{prefix}{uuid.uuid4()}.jpg"

    if not bucket:
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name.replace("/", "_"))
        raise MediaUploadError("AWS_BUCKET_NAME is not configured")

    s3 = get_s3_client()
    try:
        logger.info(f"Uploading image to S3 bucket: {bucket}, key: {file_name}")
        s3.put_object(
            Bucket=bucket,
            Key=file_name,
            Body=file_bytes,
            ContentType=content_type
        )
        return file_name
    except (NoCredentialsError, ClientError) as e:
        logger.error(f"S3 Upload failed: {e}")
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name.replace("/", "_"))
        raise MediaUploadError(f"S3 upload failed: {e}") from e
    except Exception as e:
        logger.error(f"Unexpected error during S3 upload: {e}")
        if _allow_local_fallback():
            return _save_locally(file_bytes, file_name.replace("/", "_"))
        raise MediaUploadError(f"S3 upload failed: {e}") from e


def presign_s3_key(key: str, expires_in: int = 604800) -> str:
    """Generate a fresh presigned GET URL for a stored S3 key.

    Non-S3 entries (full URLs, local /uploads paths) pass through unchanged.
    """
    if not key or key.startswith('http') or key.startswith('/'):
        return key
    bucket = os.getenv('AWS_BUCKET_NAME')
    if not bucket:
        return key
    try:
        return get_s3_client().generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': key},
            ExpiresIn=expires_in,
        )
    except Exception as e:
        logger.error(f"Failed to presign S3 key {key}: {e}")
        return key


def extract_s3_key_from_url(url: str):
    """Best-effort S3 key extraction from a legacy (possibly expired) presigned URL."""
    from urllib.parse import urlparse
    try:
        parsed = urlparse(url)
    except Exception:
        return None
    if '.amazonaws.com' not in (parsed.netloc or ''):
        return None
    path = (parsed.path or '').lstrip('/')
    bucket = os.getenv('AWS_BUCKET_NAME')
    if bucket and path.startswith(f"{bucket}/"):
        path = path[len(bucket) + 1:]
    return path or None


def resolve_media_url(entry):
    """Turn a stored media entry into a URL valid right now.

    - S3 keys (new style) get a fresh presigned URL on every read.
    - Legacy presigned URLs (possibly expired) are re-signed from their key.
    - Local /uploads paths and non-S3 URLs pass through unchanged.
    """
    if not entry or not isinstance(entry, str):
        return entry
    if entry.startswith('http'):
        key = extract_s3_key_from_url(entry)
        return presign_s3_key(key) if key else entry
    if entry.startswith('/'):
        return entry
    return presign_s3_key(entry)
