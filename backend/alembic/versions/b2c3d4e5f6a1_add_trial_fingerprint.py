"""add trial fingerprint

Revision ID: b2c3d4e5f6a1
Revises: 9a9b9c9d9e9f
Create Date: 2026-05-04 14:20:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'b2c3d4e5f6a1'
down_revision = '9a9b9c9d9e9f'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'trial_fingerprints',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('fingerprint', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(length=36), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_trial_fingerprints_id'), 'trial_fingerprints', ['id'], unique=False)
    op.create_index(op.f('ix_trial_fingerprints_fingerprint'), 'trial_fingerprints', ['fingerprint'], unique=True)
    op.create_index(op.f('ix_trial_fingerprints_user_id'), 'trial_fingerprints', ['user_id'], unique=False)

def downgrade() -> None:
    op.drop_index(op.f('ix_trial_fingerprints_user_id'), table_name='trial_fingerprints')
    op.drop_index(op.f('ix_trial_fingerprints_fingerprint'), table_name='trial_fingerprints')
    op.drop_index(op.f('ix_trial_fingerprints_id'), table_name='trial_fingerprints')
    op.drop_table('trial_fingerprints')
