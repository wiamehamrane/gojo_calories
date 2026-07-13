import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import User
from security import get_current_user
from services.promo_redemption_service import (
    lookup_promo,
    normalize_code,
    promo_public_view,
    redeem_internal,
    redeem_store_promo,
)

router = APIRouter()


class RedeemPromoRequest(BaseModel):
    code: str


@router.post("/resolve-promo")
def resolve_promo(
    body: RedeemPromoRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Look up a promo code and return platform-specific redemption instructions."""
    code_str = normalize_code(body.code)
    if not code_str:
        raise HTTPException(status_code=400, detail="Promo code is required")

    promo = lookup_promo(db, code_str)
    return promo_public_view(promo)


@router.post("/redeem-promo")
def redeem_promo(
    body: RedeemPromoRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Hybrid promo redemption:
    - internal: instant free grant via backend
    - apple/google: link purchase to influencer code, return store instructions
    """
    code_str = normalize_code(body.code)
    if not code_str:
        raise HTTPException(status_code=400, detail="Promo code is required")

    promo = lookup_promo(db, code_str)
    platform = promo.platform or "internal"

    if platform == "internal":
        return redeem_internal(db, user, promo)

    if platform in ("apple", "google"):
        return redeem_store_promo(db, user, promo)

    raise HTTPException(status_code=400, detail=f"Unsupported promo platform: {platform}")
