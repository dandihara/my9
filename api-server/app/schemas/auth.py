from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=50, pattern=r"^[A-Za-z0-9_]+$")
    password: str = Field(min_length=4, max_length=100)
    nickname: str | None = Field(default=None, max_length=50)
    my_team_id: int | None = None


class LoginRequest(BaseModel):
    username: str
    password: str


class UserRead(BaseModel):
    id: int
    username: str
    nickname: str | None = None
    my_team_id: int | None = None

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    my_team_id: int | None = None


class TokenRead(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
