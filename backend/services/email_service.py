import os
import re
import smtplib
import boto3
from botocore.exceptions import ClientError
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
import jwt
import logging

logger = logging.getLogger(__name__)

# Re-use secret key from security for JWT token signing
from security import SECRET_KEY, ALGORITHM

SES_SENDER_EMAIL = os.getenv("SES_SENDER_EMAIL", "noreply@gojocalories.com")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

# Which provider delivers the verification-code email:
#   "ses"  → AWS SES (default)
#   "smtp" → direct SMTP from Python
EMAIL_PROVIDER = os.getenv("EMAIL_PROVIDER", "ses").lower()

# Direct SMTP settings (EMAIL_PROVIDER=smtp).
SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASS = os.getenv("SMTP_PASS")
SMTP_FROM = os.getenv("SMTP_FROM", SES_SENDER_EMAIL)


def _smtp_envelope_from(from_header: str) -> str:
    """Bare address for SMTP envelope — display names break some providers."""
    match = re.search(r"<([^>]+)>", from_header or "")
    if match:
        return match.group(1).strip()
    return (from_header or "").strip()


def _html_to_plain(html_body: str) -> str:
    text = re.sub(r"<br\s*/?>", "\n", html_body, flags=re.I)
    text = re.sub(r"</p>", "\n\n", text, flags=re.I)
    text = re.sub(r"<[^>]+>", "", text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def _send_via_smtp_or_raise(to_email: str, subject: str, html_body: str) -> None:
    """Send an email directly through SMTP. Raises RuntimeError on failure."""
    if not SMTP_HOST or not SMTP_USER or not SMTP_PASS:
        raise RuntimeError(
            "SMTP is not configured. Set SMTP_HOST, SMTP_USER and SMTP_PASS."
        )
    envelope_from = _smtp_envelope_from(SMTP_FROM) or SMTP_USER
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = SMTP_FROM
    msg["To"] = to_email
    msg.attach(MIMEText(_html_to_plain(html_body), "plain", "utf-8"))
    msg.attach(MIMEText(html_body, "html", "utf-8"))
    try:
        if SMTP_PORT == 465:
            with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, timeout=15) as server:
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(envelope_from, [to_email], msg.as_string())
        else:
            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASS)
                server.sendmail(envelope_from, [to_email], msg.as_string())
    except Exception as exc:  # noqa: BLE001 - surface any SMTP error
        logger.error("SMTP email failed for %s: %s", to_email, exc)
        raise RuntimeError(f"Email could not be sent via SMTP: {exc}") from exc
    logger.info(
        "Sent email to %s via SMTP (from=%s envelope=%s)",
        to_email,
        SMTP_FROM,
        envelope_from,
    )


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

    EMAIL_PROVIDER selects delivery: "smtp" (direct Python SMTP) or
    "ses" (default AWS SES).
    """
    subject = "Your GojoCalories verification code"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a472a;">Verify your email</h2>
      <p>Enter this code in the app to verify your GojoCalories account:</p>
      <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a472a;">{code}</p>
      <p style="color: #666; font-size: 14px;">This code expires in 15 minutes. If you didn't create an account, you can ignore this email.</p>
    </div>
    """

    if EMAIL_PROVIDER == "smtp":
        _send_via_smtp_or_raise(to_email, subject, html_body)
        return

    send_email_or_raise(to_email, subject, html_body)


def send_password_reset_email_or_raise(to_email: str, code: str) -> None:
    """Send a password-reset OTP and raise if delivery fails."""
    subject = "Reset your GojoCalories password"
    html_body = f"""
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #1a472a;">Reset your password</h2>
      <p>Enter this code in the app to choose a new password:</p>
      <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a472a;">{code}</p>
      <p style="color: #666; font-size: 14px;">This code expires in 15 minutes. If you didn't request a reset, you can ignore this email.</p>
    </div>
    """
    if EMAIL_PROVIDER == "smtp":
        _send_via_smtp_or_raise(to_email, subject, html_body)
        return
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
