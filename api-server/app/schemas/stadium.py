from pydantic import BaseModel


class StadiumRead(BaseModel):
    id: int
    name: str
    city: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None

    model_config = {"from_attributes": True}
