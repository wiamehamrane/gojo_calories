"""
Verify StoreKit 2 signed transactions (JWS) from the iOS app.

The legacy verifyReceipt API expects a base64 app receipt. StoreKit 2 sends a
per-transaction JWS in purchase.verificationData.serverVerificationData instead.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.models.JWSTransactionDecodedPayload import (
    JWSTransactionDecodedPayload,
)
from appstoreserverlibrary.signed_data_verifier import (
    SignedDataVerifier,
    VerificationException,
    VerificationStatus,
)

BUNDLE_ID = "com.gojocalories.gojocalories"
CERTS_DIR = Path(__file__).resolve().parent / "certs"


def is_jws_transaction(data: str) -> bool:
    """Return True when data looks like a StoreKit 2 JWS (header.payload.signature)."""
    parts = data.strip().split(".")
    return len(parts) == 3 and all(parts)


def _load_root_certificates() -> list[bytes]:
    certificates: list[bytes] = []
    for name in (
        "AppleRootCA-G3.cer",
        "AppleIncRootCertificate.cer",
        "AppleComputerRootCertificate.cer",
    ):
        path = CERTS_DIR / name
        if path.exists():
            certificates.append(path.read_bytes())
    if not certificates:
        raise RuntimeError("Apple root certificates not found in backend/certs")
    return certificates


def verify_jws_transaction(jws: str) -> JWSTransactionDecodedPayload:
    """
    Cryptographically verify a StoreKit 2 signed transaction and decode it.

    Tries Sandbox first (TestFlight / local testing), then Production when
    APPLE_APP_ID is configured.
    """
    root_certificates = _load_root_certificates()
    app_apple_id_raw = os.getenv("APPLE_APP_ID", "").strip()
    app_apple_id = int(app_apple_id_raw) if app_apple_id_raw.isdigit() else None

    environments: list[tuple[Environment, Optional[int]]] = [
        (Environment.SANDBOX, None),
    ]
    if app_apple_id is not None:
        environments.append((Environment.PRODUCTION, app_apple_id))

    last_error: Optional[VerificationException] = None
    for environment, env_app_id in environments:
        try:
            verifier = SignedDataVerifier(
                root_certificates,
                True,
                environment,
                BUNDLE_ID,
                env_app_id,
            )
            return verifier.verify_and_decode_signed_transaction(jws)
        except VerificationException as exc:
            last_error = exc
            if exc.status == VerificationStatus.INVALID_ENVIRONMENT:
                continue
            raise

    if last_error is not None:
        raise last_error
    raise VerificationException(VerificationStatus.VERIFICATION_FAILURE)
