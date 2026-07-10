"""Clan (family plan) subscription helpers."""

import datetime
import secrets
from typing import Optional

from sqlalchemy.orm import Session

import models
from services.pricing_catalog import CLAN_MAX_MEMBERS
from services.subscription_service import revoke_subscription, sync_subscription_expiry


def get_or_create_clan_for_owner(db: Session, owner: models.User, plan_id: str) -> models.Clan:
    clan = db.query(models.Clan).filter(models.Clan.owner_user_id == owner.id).first()
    if clan:
        clan.plan_id = plan_id
        return clan

    clan = models.Clan(
        owner_user_id=owner.id,
        plan_id=plan_id,
        status="active",
        max_members=CLAN_MAX_MEMBERS,
    )
    db.add(clan)
    db.flush()

    member = models.ClanMember(
        clan_id=clan.id,
        user_id=owner.id,
        role="owner",
    )
    db.add(member)
    owner.clan_id = clan.id
    owner.subscription_source = owner.subscription_source or "clan_owner"
    return clan


def sync_clan_member_access(
    db: Session,
    clan: models.Clan,
    *,
    active: bool,
    expires_at: Optional[datetime.datetime],
) -> None:
    """Propagate owner subscription state to all clan members."""
    members = db.query(models.ClanMember).filter(models.ClanMember.clan_id == clan.id).all()
    for member in members:
        user = db.query(models.User).filter(models.User.id == member.user_id).first()
        if not user:
            continue
        if member.role == "owner":
            if active:
                user.has_paid = True
                user.subscription_expires_at = expires_at
            else:
                revoke_subscription(user)
            continue

        if active:
            user.has_paid = True
            user.subscription_source = "clan"
            user.clan_id = clan.id
            user.subscription_expires_at = expires_at
        else:
            revoke_subscription(user)
            user.clan_id = None


def activate_clan_member(
    db: Session,
    clan: models.Clan,
    member_user: models.User,
    owner: models.User,
) -> None:
    member_user.has_paid = True
    member_user.subscription_source = "clan"
    member_user.clan_id = clan.id
    member_user.subscription_expires_at = owner.subscription_expires_at
    sync_subscription_expiry(member_user, owner.subscription_expires_at)


def create_invite(db: Session, clan: models.Clan, email: str) -> models.ClanInvite:
    token = secrets.token_urlsafe(24)
    invite = models.ClanInvite(
        clan_id=clan.id,
        email=email.lower().strip(),
        token=token,
        status="pending",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(days=7),
    )
    db.add(invite)
    return invite


def member_count(db: Session, clan_id: str) -> int:
    return (
        db.query(models.ClanMember)
        .filter(models.ClanMember.clan_id == clan_id, models.ClanMember.role == "member")
        .count()
    )


def pending_addon_slots(db: Session, clan_id: str) -> int:
    """Members invited but not yet billing-active."""
    return (
        db.query(models.ClanMember)
        .filter(
            models.ClanMember.clan_id == clan_id,
            models.ClanMember.role == "member",
            models.ClanMember.addon_active.is_(False),
        )
        .count()
    )
