"""requeue recent boxscores for new stats

Revision ID: a52bc4e74d31
Revises: f41ac9d63b20
"""
from collections.abc import Sequence

from alembic import op


revision: str = "a52bc4e74d31"
down_revision: str | None = "f41ac9d63b20"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE games
        SET boxscore_finalized_at = NULL
        WHERE status = 'completed'
          AND game_date >= CURRENT_DATE - INTERVAL '30 days'
        """
    )


def downgrade() -> None:
    pass
