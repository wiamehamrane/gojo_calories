import os
import boto3
import httpx
from botocore.exceptions import ClientError
from datetime import datetime, timedelta
import jwt
import logging

logger = logging.getLogger(__name__)

# Re-use secret key from security for JWT token signing
from security import SECRET_KEY, ALGORITHM

SES_SENDER_EMAIL = os.getenv("SES_SENDER_EMAIL", "noreply@gojocalories.com")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

# Which provider delivers the verification-code email: "ses" (default) or
# "firebase" (calls the sendOtpEmail Cloud Function).
EMAIL_PROVIDER = os.getenv("EMAIL_PROVIDER", "ses").lower()
FIREBASE_OTP_FUNCTION_URL = os.getenv("FIREBASE_OTP_FUNCTION_URL")
FIREBASE_OTP_SHARED_SECRET = os.getenv("FIREBASE_OTP_SHARED_SECRET")


def _send_verification_code_via_firebase(to_email: str, code: str) -> None:
    """Deliver the OTP email through the Firebase Cloud Function.

    The backend still generates and verifies the code — Firebase only sends
    the email. Raises RuntimeError on any failure so callers can surface a 503.
    """
    if not FIREBASE_OTP_FUNCTION_URL or not FIREBASE_OTP_SHARED_SECRET:
        raise RuntimeError(
            "Firebase OTP email is not configured. Set FIREBASE_OTP_FUNCTION_URL "
            "and FIREBASE_OTP_SHARED_SECRET."
        )
    try:
        response = httpx.post(
            FIREBASE_OTP_FUNCTION_URL,
            json={"email": to_email, "code": code},
            headers={"x-otp-secret": FIREBASE_OTP_SHARED_SECRET},
            timeout=10.0,
        )
    except Exception as exc:  # noqa: BLE001 - surface any transport error
        logger.error("Firebase OTP email transport error for %s: %s", to_email, exc)
        raise RuntimeError(f"Email could not be sent via Firebase: {exc}") from exc

    if response.status_code != 200:
        logger.error(
            "Firebase OTP email failed for %s: [%s] %s",
            to_email,
            response.status_code,
            response.text,
        )
        raise RuntimeError(
            f"Email could not be sent via Firebase (HTTP {response.status_code})."
        )
    logger.info("Sent OTP email to %s via Firebase", to_email)


def get_ses_client():
    """Use explicit keys when set; otherwise rely on the ECS task IAM role."""
    kwargs = {"region_name": AWS_REGION}
    access_key = os.getenv("AWS_ACCESS_KEY_ID")
    secret_key = os.getenv("AWS_SECRET_ACCESS_KEY")
    if access_key and secret_key:
        kwargs["aws_access_key_id"] = access_key
        kwargs["aws_secret_access_key"] = secret_key
    return boto3.client("ses", **kwargs)

def send_verification_code_email(to_email: str, code: str) -> bool:
    """Send a 6-digit email verification code."""
    subject = "Your GojoCalories verification code"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a472a;">Verify your email</h2>
      <p>Enter this code in the app to verify your GojoCalories account:</p>
      <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a472a;">{code}</p>
      <p style="color: #666; font-size: 14px;">This code expires in 15 minutes. If you didn't create an account, you can ignore this email.</p>
    </div>
    """
    return send_email(to_email, subject, html_body)


def send_verification_code_email_or_raise(to_email: str, code: str) -> None:
    """Send OTP email and raise if delivery fails.

    Uses the Firebase Cloud Function when EMAIL_PROVIDER=firebase, otherwise SES.
    """
    if EMAIL_PROVIDER == "firebase":
        _send_verification_code_via_firebase(to_email, code)
        return

    subject = "Your GojoCalories verification code"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a472a;">Verify your email</h2>
      <p>Enter this code in the app to verify your GojoCalories account:</p>
      <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a472a;">{code}</p>
      <p style="color: #666; font-size: 14px;">This code expires in 15 minutes. If you didn't create an account, you can ignore this email.</p>
    </div>
    """
    send_email_or_raise(to_email, subject, html_body)


def send_email(to_email: str, subject: str, html_body: str) -> bool:
    """Send an email using AWS SES. Returns True on success."""
    client = get_ses_client()
    try:
        response = client.send_email(
            Destination={"ToAddresses": [to_email]},
            Message={
                "Body": {
                    "Html": {"Charset": "UTF-8", "Data": html_body},
                },
                "Subject": {"Charset": "UTF-8", "Data": subject},
            },
            Source=SES_SENDER_EMAIL,
        )
        logger.info(
            "Sent email to %s from %s (message_id=%s)",
            to_email,
            SES_SENDER_EMAIL,
            response.get("MessageId"),
        )
        return True
    except ClientError as e:
        error = e.response.get("Error", {})
        message = error.get("Message", str(e))
        code = error.get("Code", "Unknown")
        logger.error(
            "Failed to send email to %s from %s: [%s] %s",
            to_email,
            SES_SENDER_EMAIL,
            code,
            message,
        )
        return False


def send_email_or_raise(to_email: str, subject: str, html_body: str) -> None:
    """Send email and raise a descriptive error when SES rejects it."""
    client = get_ses_client()
    try:
        response = client.send_email(
            Destination={"ToAddresses": [to_email]},
            Message={
                "Body": {
                    "Html": {"Charset": "UTF-8", "Data": html_body},
                },
                "Subject": {"Charset": "UTF-8", "Data": subject},
            },
            Source=SES_SENDER_EMAIL,
        )
        logger.info(
            "Sent email to %s from %s (message_id=%s)",
            to_email,
            SES_SENDER_EMAIL,
            response.get("MessageId"),
        )
    except ClientError as e:
        error = e.response.get("Error", {})
        message = error.get("Message", str(e))
        code = error.get("Code", "Unknown")
        logger.error(
            "Failed to send email to %s from %s: [%s] %s",
            to_email,
            SES_SENDER_EMAIL,
            code,
            message,
        )
        if "not verified" in message.lower():
            raise RuntimeError(
                "Email could not be sent. AWS SES is in sandbox mode — "
                "verify the recipient address in SES, or request production access."
            ) from e
        if code in {"AccessDenied", "UnauthorizedOperation"}:
            raise RuntimeError(
                "Email could not be sent. The API server lacks SES send permissions."
            ) from e
        raise RuntimeError(f"Email could not be sent: {message}") from e
