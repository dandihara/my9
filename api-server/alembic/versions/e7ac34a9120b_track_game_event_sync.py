"""track game event sync

Revision ID: e7ac34a9120b
Revises: d91f3c72a601
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "e7ac34a9120b"
down_revision: str | None = "d91f3c72a601"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "games",
        sa.Column("events_synced_at", sa.DateTime(timezone=True), nullable=True),
    )
    # Force one complete-season pass after the PA fields and official KBO event
    # summary collector are deployed.
    op.execute(
        """
        UPDATE games
        SET boxscore_finalized_at = NULL,
            events_synced_at = NULL
        WHERE season_year = EXTRACT(YEAR FROM CURRENT_DATE)
          AND status = 'completed'
        """
    )


def downgrade() -> None:
    op.drop_column("games", "events_synced_at")
