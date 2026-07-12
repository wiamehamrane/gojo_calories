"""
Optional App Store Connect API integration for generating subscription offer codes.

Requires environment variables:
  APPLE_ASC_KEY_ID
  APPLE_ASC_ISSUER_ID
  APPLE_ASC_PRIVATE_KEY  (PEM contents or base64)
  APPLE_ASC_OFFER_CODE_ID_<PLAN>  e.g. APPLE_ASC_OFFER_CODE_ID_MONTHLY

Create the subscription offer in App Store Connect first, then paste its resource ID.
"""

import os
import time
from typing import Optional

import httpx
import jwt

ASC_BASE = "https://api.appstoreconnect.apple.com"


def _asc_configured() -> bool:
    return bool(
        os.getenv("APPLE_ASC_KEY_ID")
        and os.getenv("APPLE_ASC_ISSUER_ID")
        and os.getenv("APPLE_ASC_PRIVATE_KEY")
    )


def _private_key_pem() -> str:
    raw = os.getenv("APPLE_ASC_PRIVATE_KEY", "")
    if "BEGIN PRIVATE KEY" in raw:
        return raw
    import base64
    decoded = base64.b64decode(raw).decode("utf-8")
    if "BEGIN PRIVATE KEY" not in decoded:
        return f"-----BEGIN PRIVATE KEY-----\n{decoded}\n-----END PRIVATE KEY-----"
    return decoded


def _asc_token() -> str:
    key_id = os.getenv("APPLE_ASC_KEY_ID")
    issuer_id = os.getenv("APPLE_ASC_ISSUER_ID")
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, _private_key_pem(), algorithm="ES256", headers={"kid": key_id})


def offer_code_id_for_plan(plan_type: str) -> Optional[str]:
    env_key = f"APPLE_ASC_OFFER_CODE_ID_{plan_type.upper()}"
    return os.getenv(env_key) or os.getenv("APPLE_ASC_OFFER_CODE_ID")


def generate_one_time_codes(
    *,
    plan_type: str,
    number_of_codes: int,
    expiration_date: str,
    environment: str = "production",
) -> list[str]:
    """
    Request a batch of one-time Apple offer codes.
    expiration_date format: YYYY-MM-DD
    Returns list of code strings (may be empty if still processing).
    """
    if not _asc_configured():
        raise RuntimeError(
            "App Store Connect API is not configured. "
            "Set APPLE_ASC_KEY_ID, APPLE_ASC_ISSUER_ID, and APPLE_ASC_PRIVATE_KEY."
        )

    offer_code_id = offer_code_id_for_plan(plan_type)
    if not offer_code_id:
        raise RuntimeError(
            f"No Apple offer code ID configured for plan '{plan_type}'. "
            f"Set APPLE_ASC_OFFER_CODE_ID_{plan_type.upper()} in environment."
        )

    token = _asc_token()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {
        "data": {
            "type": "subscriptionOfferCodeOneTimeUseCodes",
            "attributes": {
                "numberOfCodes": number_of_codes,
                "expirationDate": expiration_date,
            },
            "relationships": {
                "offerCode": {
                    "data": {"type": "subscriptionOfferCodes", "id": offer_code_id}
                }
            },
        }
    }

    with httpx.Client(timeout=60.0) as client:
        resp = client.post(
            f"{ASC_BASE}/v1/subscriptionOfferCodeOneTimeUseCodes",
            headers=headers,
            json=body,
        )
        resp.raise_for_status()
        batch_id = resp.json()["data"]["id"]

        # Poll for generated values
        for _ in range(12):
            time.sleep(5)
            values_resp = client.get(
                f"{ASC_BASE}/v1/subscriptionOfferCodeOneTimeUseCodes/{batch_id}/values",
                headers=headers,
            )
            if values_resp.status_code != 200:
                continue
            data = values_resp.json().get("data", [])
            if data:
                return [item.get("attributes", {}).get("code", "") for item in data if item.get("attributes", {}).get("code")]
        return []
