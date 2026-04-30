import random
import string
import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from database import get_db
from models import User, Referral, Withdrawal
from security import get_current_user_id

router = APIRouter()


# ── Helpers ──────────────────────────────────────────────────────────────────

def _generate_code(length: int = 6) -> str:
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


def _ensure_referral_code(user: User, db: Session) -> str:
    """Lazily assign a referral code to existing users who have none."""
    if user.referral_code:
        return user.referral_code
    while True:
        code = _generate_code()
        existing = db.query(User).filter(User.referral_code == code).first()
        if not existing:
            break
    user.referral_code = code
    db.commit()
    db.refresh(user)
    return code


# ── Schemas ───────────────────────────────────────────────────────────────────

class WithdrawRequest(BaseModel):
    amount: float
    method: str = "PayPal"  # "PayPal" | "Bank Transfer"


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/me")
def get_my_referrals(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    code = _ensure_referral_code(user, db)

    referrals = db.query(Referral).filter(Referral.referrer_id == user_id).all()
    withdrawals = db.query(Withdrawal).filter(Withdrawal.user_id == user_id).all()

    total_earned = sum(r.amount for r in referrals)
    total_withdrawn = sum(
        w.amount for w in withdrawals if w.status == "paid"
    )

    referral_history = [
        {
            "id": r.id,
            "referred_user_id": r.referred_user_id,
            "referred_name": r.referred_user.name if r.referred_user else "Friend",
            "amount": r.amount,
            "created_at": r.created_at.isoformat(),
        }
        for r in referrals
    ]

    withdrawal_history = [
        {
            "id": w.id,
            "amount": w.amount,
            "method": w.method,
            "status": w.status,
            "created_at": w.created_at.isoformat(),
        }
        for w in withdrawals
    ]

    return {
        "referral_code": code,
        "balance": round(user.referral_balance, 2),
        "total_earned": round(total_earned, 2),
        "total_referrals": len(referrals),
        "total_withdrawn": round(total_withdrawn, 2),
        "referral_history": referral_history,
        "withdrawal_history": withdrawal_history,
    }


@router.post("/withdraw")
def request_withdrawal(
    body: WithdrawRequest,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if body.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")

    if body.amount > user.referral_balance:
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient balance. Available: ${user.referral_balance:.2f}",
        )

    # Deduct balance and create withdrawal record
    user.referral_balance = round(user.referral_balance - body.amount, 2)
    withdrawal = Withdrawal(
        user_id=user_id,
        amount=body.amount,
        method=body.method,
        status="pending",
        created_at=datetime.datetime.utcnow(),
    )
    db.add(withdrawal)
    db.commit()
    db.refresh(withdrawal)

    return {
        "status": "success",
        "message": "Withdrawal request submitted. Processing within 3-5 business days.",
        "withdrawal_id": withdrawal.id,
        "remaining_balance": user.referral_balance,
    }
