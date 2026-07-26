from worker.config import settings
from worker.sources.base import BaseballDataSource
from worker.sources.kbo_source import KboSource
from worker.sources.mock_source import MockBaseballDataSource


def get_data_source() -> BaseballDataSource:
    if settings.data_source_mode == "kbo":
        return KboSource()
    return MockBaseballDataSource()
