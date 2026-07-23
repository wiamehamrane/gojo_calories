"""Coach / peer share-access helpers."""

import datetime
import os
import secrets
from typing import Optional

from fastapi import HTTPException
from sqlalchemy.orm import Session

import models

DEFAULT_SCOPES = "nutrition,exercises"
VALID_SCOPES = frozenset({"nutrition", "exercises", "health_sync", "body_journal"})
INVITE_TTL_DAYS = 14
SHARE_LINK_BASE = os.getenv(
    "SHARE_LINK_BASE",
    "https://api.gojocalories.com/share/join",
)



def create_invite(
    db: Session,
    *,
    viewer: models.User,
    email: Optional[str] = None,
    scopes: Optional[str] = None,
) -> models.ShareGrant:
    email_norm = email.strip().lower() if email else None
    if email_norm and email_norm == (viewer.email or "").lower():
        raise HTTPException(status_code=400, detail="You cannot invite yourself")

    if email_norm:
        existing_active = (
            db.query(models.ShareGrant)
            .join(models.User, models.ShareGrant.owner_user_id == models.User.id)
            .filter(
                models.ShareGrant.viewer_user_id == viewer.id,
                models.User.email == email_norm,
                models.ShareGrant.status == "active",
            )
            .first()
        )
        if existing_active:
            raise HTTPException(status_code=400, detail="You already have access to this user")

        # Refresh pending invite for same email
        pending = (
            db.query(models.ShareGrant)
            .filter(
                models.ShareGrant.viewer_user_id == viewer.id,
                models.ShareGrant.invite_email == email_norm,
                models.ShareGrant.status == "pending",
            )
            .first()
        )
        if pending:
            pending.token = secrets.token_urlsafe(24)
            pending.expires_at = datetime.datetime.utcnow() + datetime.timedelta(days=INVITE_TTL_DAYS)
            pending.scopes = scopes or DEFAULT_SCOPES
            db.commit()
            db.refresh(pending)
            return pending

    grant = models.ShareGrant(
        viewer_user_id=viewer.id,
        invite_email=email_norm,
        token=secrets.token_urlsafe(24),
        status="pending",
        scopes=scopes or DEFAULT_SCOPES,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(days=INVITE_TTL_DAYS),
    )
    db.add(grant)
    db.commit()
    db.refresh(grant)
    return grant


def accept_invite(db: Session, *, owner: models.User, token: str) -> models.ShareGrant:
    grant = db.query(models.ShareGrant).filter(models.ShareGrant.token == token).first()
    if not grant:
        raise HTTPException(status_code=404, detail="Invite not found")
    if grant.status == "active" and grant.owner_user_id == owner.id:
        return grant
    if grant.status != "pending":
        raise HTTPException(status_code=400, detail=f"Invite is {grant.status}")
    if grant.expires_at < datetime.datetime.utcnow():
        grant.status = "expired"
        db.commit()
        raise HTTPException(status_code=400, detail="This invite has expired")
    if grant.viewer_user_id == owner.id:
        raise HTTPException(status_code=400, detail="You cannot accept your own invite")
    if grant.invite_email and owner.email and grant.invite_email.lower() != owner.email.lower():
        raise HTTPException(
            status_code=403,
            detail="This invite was sent to a different email address",
        )

    # One active grant per viewer↔owner pair
    dup = (
        db.query(models.ShareGrant)
        .filter(
            models.ShareGrant.viewer_user_id == grant.viewer_user_id,
            models.ShareGrant.owner_user_id == owner.id,
            models.ShareGrant.status == "active",
            models.ShareGrant.id != grant.id,
        )
        .first()
    )
    if dup:
        grant.status = "revoked"
        db.commit()
        raise HTTPException(status_code=400, detail="Access is already active with this person")

    grant.owner_user_id = owner.id
    grant.status = "active"
    grant.accepted_at = datetime.datetime.utcnow()
    db.commit()
    db.refresh(grant)
    return grant


def require_active_share(
    db: Session,
    *,
    viewer_id: str,
    owner_id: str,
    scope: Optional[str] = None,
) -> models.ShareGrant:
    grant = (
        db.query(models.ShareGrant)
        .filter(
            models.ShareGrant.viewer_user_id == viewer_id,
            models.ShareGrant.owner_user_id == owner_id,
            models.ShareGrant.status == "active",
        )
        .first()
    )
    if not grant:
        raise HTTPException(status_code=403, detail="You do not have access to this diary")
    if scope:
        allowed = {s.strip() for s in (grant.scopes or "").split(",") if s.strip()}
        if scope not in allowed:
            raise HTTPException(status_code=403, detail=f"Missing permission: {scope}")
    return grant


def serialize_grant(grant: models.ShareGrant) -> dict:
    return {
        "id": grant.id,
        "status": grant.status,
        "scopes": [s.strip() for s in (grant.scopes or "").split(",") if s.strip()],
        "invite_email": grant.invite_email,
        "share_link": f"{SHARE_LINK_BASE}?token={grant.token}",
        "token": grant.token,
        "expires_at": grant.expires_at.isoformat() if grant.expires_at else None,
        "accepted_at": grant.accepted_at.isoformat() if grant.accepted_at else None,
        "created_at": grant.created_at.isoformat() if grant.created_at else None,
        "owner": {
            "user_id": grant.owner_user_id,
            "name": grant.owner.name if grant.owner else None,
            "email": grant.owner.email if grant.owner else None,
        }
        if grant.owner_user_id
        else None,
        "viewer": {
            "user_id": grant.viewer_user_id,
            "name": grant.viewer.name if grant.viewer else None,
            "email": grant.viewer.email if grant.viewer else None,
        }
        if grant.viewer
        else None,
    }


def local_day_window(date_str: Optional[str], tz_offset: int):
    import datetime as dt

    if date_str:
        try:
            target_date = dt.datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            target_date = dt.datetime.utcnow().date()
    else:
        target_date = dt.datetime.utcnow().date()

    local_midnight = dt.datetime.combine(target_date, dt.time.min)
    window_start = local_midnight - dt.timedelta(minutes=tz_offset or 0)
    window_end = window_start + dt.timedelta(days=1)
    return target_date, window_start, window_end
