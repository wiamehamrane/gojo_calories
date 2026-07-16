"""Clan (family plan) management routes."""

import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
import models
from security import get_current_user
from services.clan_service import (
    activate_clan_member,
    create_invite,
    get_or_create_clan_for_owner,
    member_count,
    pending_addon_slots,
    sync_clan_member_access,
)
from services.pricing_catalog import CLAN_MAX_MEMBERS, build_catalog, clan_addon_product_for_plan

router = APIRouter()


class InviteRequest(BaseModel):
    email: str


class AcceptInviteRequest(BaseModel):
    token: str


def _require_owner_clan(db: Session, user: models.User) -> models.Clan:
    clan = db.query(models.Clan).filter(models.Clan.owner_user_id == user.id).first()
    if not clan:
        raise HTTPException(status_code=404, detail="You do not have an active clan")
    return clan


def _serialize_clan(db: Session, clan: models.Clan, viewer: models.User) -> dict:
    members = (
        db.query(models.ClanMember)
        .filter(models.ClanMember.clan_id == clan.id)
        .order_by(models.ClanMember.joined_at)
        .all()
    )
    invites = (
        db.query(models.ClanInvite)
        .filter(
            models.ClanInvite.clan_id == clan.id,
            models.ClanInvite.status == "pending",
        )
        .all()
    )

    addon_product_id = clan_addon_product_for_plan(clan.plan_id)

    return {
        "id": clan.id,
        "plan_id": clan.plan_id,
        "status": clan.status,
        "max_members": clan.max_members,
        "member_count": member_count(db, clan.id),
        "pending_addon_slots": pending_addon_slots(db, clan.id),
        "is_owner": clan.owner_user_id == viewer.id,
        "addon_product_id": addon_product_id,
        "members": [
            {
                "user_id": m.user_id,
                "name": m.user.name if m.user else None,
                "email": m.user.email if m.user else None,
                "role": m.role,
                "addon_active": m.addon_active,
                "joined_at": m.joined_at.isoformat() if m.joined_at else None,
            }
            for m in members
        ],
        "pending_invites": [
            {
                "id": i.id,
                "email": i.email,
                "expires_at": i.expires_at.isoformat(),
            }
            for i in invites
        ],
    }


@router.get("/me")
def get_my_clan(
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.clan_id:
        clan = db.query(models.Clan).filter(models.Clan.id == user.clan_id).first()
        if clan:
            return {"has_clan": True, "clan": _serialize_clan(db, clan, user)}

    owned = db.query(models.Clan).filter(models.Clan.owner_user_id == user.id).first()
    if owned:
        return {"has_clan": True, "clan": _serialize_clan(db, owned, user)}

    return {
        "has_clan": False,
        "clan": None,
        "can_create": user.has_paid and user.subscription_source in ("apple", "google", "stripe", "clan_owner", "admin_grant"),
        "catalog": build_catalog()["clan_addons"],
        "max_members": CLAN_MAX_MEMBERS,
    }


@router.post("/invite")
def invite_member(
    body: InviteRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not user.has_paid:
        raise HTTPException(status_code=403, detail="An active subscription is required")

    plan_id = user.subscription_plan or "monthly"
    clan = get_or_create_clan_for_owner(db, user, plan_id)

    if member_count(db, clan.id) >= clan.max_members:
        raise HTTPException(status_code=400, detail=f"Clan is full (max {clan.max_members} members)")

    email = body.email.lower().strip()
    if email == user.email.lower():
        raise HTTPException(status_code=400, detail="You cannot invite yourself")

    existing_user = db.query(models.User).filter(models.User.email == email).first()
    if existing_user and existing_user.clan_id:
        raise HTTPException(status_code=400, detail="This user is already in a clan")

    pending = (
        db.query(models.ClanInvite)
        .filter(
            models.ClanInvite.clan_id == clan.id,
            models.ClanInvite.email == email,
            models.ClanInvite.status == "pending",
        )
        .first()
    )
    if pending:
        raise HTTPException(status_code=400, detail="An invite is already pending for this email")

    invite = create_invite(db, clan, email)
    db.commit()
    db.refresh(invite)

    return {
        "status": "success",
        "invite_id": invite.id,
        "token": invite.token,
        "share_link": f"https://gojocalories.com/clan/join?token={invite.token}",
        "expires_at": invite.expires_at.isoformat(),
    }


@router.post("/accept")
def accept_invite(
    body: AcceptInviteRequest,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.clan_id:
        raise HTTPException(status_code=400, detail="You are already in a clan")

    invite = (
        db.query(models.ClanInvite)
        .filter(models.ClanInvite.token == body.token.strip())
        .first()
    )
    if not invite or invite.status != "pending":
        raise HTTPException(status_code=404, detail="Invalid or expired invite")

    if invite.expires_at < datetime.datetime.utcnow():
        invite.status = "expired"
        db.commit()
        raise HTTPException(status_code=400, detail="This invite has expired")

    if user.email.lower() != invite.email.lower():
        raise HTTPException(status_code=403, detail="This invite was sent to a different email address")

    clan = db.query(models.Clan).filter(models.Clan.id == invite.clan_id).first()
    if not clan or clan.status != "active":
        raise HTTPException(status_code=400, detail="Clan is no longer active")

    if member_count(db, clan.id) >= clan.max_members:
        raise HTTPException(status_code=400, detail="Clan is full")

    owner = db.query(models.User).filter(models.User.id == clan.owner_user_id).first()
    if not owner or not owner.has_paid:
        raise HTTPException(status_code=400, detail="Clan owner subscription is not active")

    member = models.ClanMember(
        clan_id=clan.id,
        user_id=user.id,
        role="member",
        addon_active=False,
    )
    db.add(member)
    invite.status = "accepted"
    user.clan_id = clan.id
    db.commit()

    return {
        "status": "success",
        "message": "Joined clan. Waiting for owner to activate your membership.",
        "clan_id": clan.id,
        "addon_product_id": clan_addon_product_for_plan(clan.plan_id),
    }


@router.post("/activate-member/{member_user_id}")
def activate_member_addon(
    member_user_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a clan member as billing-active after owner purchases add-on (IAP verified separately)."""
    clan = _require_owner_clan(db, user)
    if not user.has_paid:
        raise HTTPException(status_code=403, detail="Owner subscription is not active")

    member_row = (
        db.query(models.ClanMember)
        .filter(
            models.ClanMember.clan_id == clan.id,
            models.ClanMember.user_id == member_user_id,
            models.ClanMember.role == "member",
        )
        .first()
    )
    if not member_row:
        raise HTTPException(status_code=404, detail="Member not found in your clan")

    member_user = db.query(models.User).filter(models.User.id == member_user_id).first()
    if not member_user:
        raise HTTPException(status_code=404, detail="User not found")

    member_row.addon_active = True
    activate_clan_member(db, clan, member_user, user)
    db.commit()

    return {"status": "success", "user_id": member_user_id}


@router.delete("/members/{member_user_id}")
def remove_member(
    member_user_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    clan = _require_owner_clan(db, user)

    member_row = (
        db.query(models.ClanMember)
        .filter(
            models.ClanMember.clan_id == clan.id,
            models.ClanMember.user_id == member_user_id,
            models.ClanMember.role == "member",
        )
        .first()
    )
    if not member_row:
        raise HTTPException(status_code=404, detail="Member not found")

    member_user = db.query(models.User).filter(models.User.id == member_user_id).first()
    if member_user:
        from services.subscription_service import revoke_subscription
        revoke_subscription(member_user)

    db.delete(member_row)
    db.commit()
    return {"status": "success"}


@router.delete("/invites/{invite_id}")
def cancel_invite(
    invite_id: str,
    user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    clan = _require_owner_clan(db, user)
    invite = (
        db.query(models.ClanInvite)
        .filter(models.ClanInvite.id == invite_id, models.ClanInvite.clan_id == clan.id)
        .first()
    )
    if not invite:
        raise HTTPException(status_code=404, detail="Invite not found")

    invite.status = "canceled"
    db.commit()
    return {"status": "success"}
