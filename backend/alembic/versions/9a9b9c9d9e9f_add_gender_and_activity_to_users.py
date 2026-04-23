"""add gender and activity to users

Revision ID: 9a9b9c9d9e9f
Revises: 3f035f084e45
Create Date: 2026-04-23 15:58:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '9a9b9c9d9e9f'
down_revision = '3f035f084e45'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('gender', sa.String(), nullable=True))
    op.add_column('users', sa.Column('activity_level', sa.String(), nullable=True))


def downgrade():
    op.drop_column('users', 'activity_level')
    op.drop_column('users', 'gender')
