"""requeue recent boxscores for steals

Revision ID: b63df91e2847
Revises: a52bc4e74d31
"""
from collections.abc import Sequence

from alembic import op


revision: str = "b63df91e2847"
down_revision: str | None = "a52bc4e74d31"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # The KBO steals value is parsed from #tblEtc as of this revision.
    # Re-open recent completed games so the worker can populate the new values.
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
