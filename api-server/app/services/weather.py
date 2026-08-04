from __future__ import annotations

from datetime import datetime, timedelta, timezone

import httpx

from app.models.stadium import Stadium

WEATHER_CACHE_TTL = timedelta(minutes=20)
_weather_cache: dict[tuple[float, float], tuple[datetime, dict[str, object]]] = {}

# Database coordinates take precedence. These fallbacks cover the stadium
# names collected from the KBO schedule.
STADIUM_COORDINATES: tuple[tuple[str, tuple[float, float]], ...] = (
    ("잠실", (37.5122, 127.0719)),
    ("고척", (37.4982, 126.8671)),
    ("수원", (37.2998, 127.0095)),
    ("문학", (37.4369, 126.6933)),
    ("인천", (37.4369, 126.6933)),
    ("대전", (36.3171, 127.4292)),
    ("광주", (35.1681, 126.8891)),
    ("대구", (35.8411, 128.6812)),
    ("사직", (35.1940, 129.0615)),
    ("창원", (35.2225, 128.5822)),
    ("마산", (35.2225, 128.5822)),
    ("포항", (36.0085, 129.3594)),
    ("울산", (35.5321, 129.2656)),
)


def stadium_coordinates(stadium: Stadium) -> tuple[float, float] | None:
    if stadium.latitude is not None and stadium.longitude is not None:
        return stadium.latitude, stadium.longitude
    for keyword, coordinates in STADIUM_COORDINATES:
        if keyword in stadium.name:
            return coordinates
    return None


def weather_condition(weather_code: int, is_day: bool) -> str:
    if weather_code in {71, 73, 75, 77, 85, 86}:
        return "snow"
    if weather_code in {
        51,
        53,
        55,
        56,
        57,
        61,
        63,
        65,
        66,
        67,
        80,
        81,
        82,
        95,
        96,
        99,
    }:
        return "rain"
    if weather_code in {1, 2, 3, 45, 48}:
        return "cloudy"
    return "clear" if is_day else "night"


async def fetch_stadium_weather(
    stadium: Stadium,
    *,
    game_id: int,
) -> dict[str, object] | None:
    coordinates = stadium_coordinates(stadium)
    if coordinates is None:
        return None

    cache_key = (round(coordinates[0], 4), round(coordinates[1], 4))
    now = datetime.now(timezone.utc)
    cached = _weather_cache.get(cache_key)
    if cached is not None and now - cached[0] < WEATHER_CACHE_TTL:
        return {
            **cached[1],
            "stadium_name": stadium.name,
            "game_id": game_id,
        }

    try:
        # 날씨는 장식 정보이므로 느린 외부 API가 홈 대시보드 전체를
        # 붙잡지 않도록 짧게 실패시키고 다음 갱신에서 다시 시도한다.
        async with httpx.AsyncClient(timeout=1.5) as client:
            response = await client.get(
                "https://api.open-meteo.com/v1/forecast",
                params={
                    "latitude": coordinates[0],
                    "longitude": coordinates[1],
                    "current": "temperature_2m,weather_code,is_day",
                    "timezone": "Asia/Seoul",
                },
            )
            response.raise_for_status()
            current = response.json()["current"]
        code = int(current["weather_code"])
        is_day = bool(current["is_day"])
        payload: dict[str, object] = {
            "condition": weather_condition(code, is_day),
            "temperature_c": round(float(current["temperature_2m"]), 1),
            "weather_code": code,
            "is_day": is_day,
            "stadium_name": stadium.name,
            "game_id": game_id,
            "source": "Open-Meteo",
            "fetched_at": now,
        }
        _weather_cache[cache_key] = (now, payload)
        return payload
    except (httpx.HTTPError, KeyError, TypeError, ValueError):
        # Weather must never make the dashboard unavailable.
        return None
