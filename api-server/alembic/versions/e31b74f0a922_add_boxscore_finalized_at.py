"""add boxscore finalized timestamp

Revision ID: e31b74f0a922
Revises: d8f4a2c901b7
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "e31b74f0a922"
down_revision: str | None = "d8f4a2c901b7"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "games",
        sa.Column("boxscore_finalized_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("games", "boxscore_finalized_at")
