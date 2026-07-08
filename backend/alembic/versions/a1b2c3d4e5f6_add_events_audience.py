"""Add audience column to events

Revision ID: a1b2c3d4e5f6
Revises: 909cb89f5189
Create Date: 2026-07-08 16:42:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '909cb89f5189'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'events',
        sa.Column('audience', sa.String(), nullable=False, server_default='mixed'),
    )
    op.create_index(op.f('ix_events_audience'), 'events', ['audience'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_events_audience'), table_name='events')
    op.drop_column('events', 'audience')
