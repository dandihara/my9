"""add season metric tables

Revision ID: c317ad18d2a1
Revises: bacdcdbe886d
"""
from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "c317ad18d2a1"
down_revision: str | None = "bacdcdbe886d"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    for column in ("doubles", "triples", "hbp", "sf"):
        op.add_column("batting_game_stats", sa.Column(column, sa.Integer(), nullable=False, server_default="0"))
    for column in ("home_runs", "batters_faced"):
        op.add_column("pitching_game_stats", sa.Column(column, sa.Integer(), nullable=False, server_default="0"))

    op.create_table(
        "player_season_batting_metrics",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("season_year", sa.Integer(), nullable=False, index=True),
        sa.Column("player_id", sa.Integer(), sa.ForeignKey("players.id"), nullable=False, index=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False, index=True),
        *[sa.Column(name, sa.Integer(), nullable=False, server_default="0") for name in ("games", "pa", "ab", "r", "h", "doubles", "triples", "hr", "rbi", "bb", "hbp", "sf", "so")],
        *[sa.Column(name, sa.Numeric(8, 3), nullable=False, server_default="0") for name in ("avg", "obp", "slg", "ops", "estimated_woba", "estimated_wrc", "estimated_wrc_plus")],
        sa.Column("qualification_pa", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_qualified", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("season_year", "player_id", "team_id"),
    )
    op.create_table(
        "player_season_pitching_metrics",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("season_year", sa.Integer(), nullable=False, index=True),
        sa.Column("player_id", sa.Integer(), sa.ForeignKey("players.id"), nullable=False, index=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False, index=True),
        sa.Column("games", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("innings_pitched", sa.Numeric(7, 1), nullable=False, server_default="0"),
        *[sa.Column(name, sa.Integer(), nullable=False, server_default="0") for name in ("hits", "home_runs", "batters_faced", "runs", "earned_runs", "walks", "strikeouts", "pitches")],
        *[sa.Column(name, sa.Numeric(7, 2), nullable=False, server_default="0") for name in ("era", "whip", "k_per_nine", "bb_per_nine", "k_bb", "fip", "k_bb_percent")],
        sa.Column("qualification_innings", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_qualified", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("season_year", "player_id", "team_id"),
    )
    op.create_table(
        "player_season_wpa_metrics",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("season_year", sa.Integer(), nullable=False, index=True),
        sa.Column("player_id", sa.Integer(), sa.ForeignKey("players.id"), nullable=False, index=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False, index=True),
        sa.Column("games", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("batting_wpa", sa.Numeric(9, 4), nullable=False, server_default="0"),
        sa.Column("pitching_wpa", sa.Numeric(9, 4), nullable=False, server_default="0"),
        sa.Column("total_wpa", sa.Numeric(9, 4), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("season_year", "player_id", "team_id"),
    )


def downgrade() -> None:
    op.drop_table("player_season_wpa_metrics")
    op.drop_table("player_season_pitching_metrics")
    op.drop_table("player_season_batting_metrics")
    for column in ("home_runs", "batters_faced"):
        op.drop_column("pitching_game_stats", column)
    for column in ("doubles", "triples", "hbp", "sf"):
        op.drop_column("batting_game_stats", column)
