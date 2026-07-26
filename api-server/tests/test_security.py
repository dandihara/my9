import unittest

from app.core.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


class SecurityTest(unittest.TestCase):
    def test_password_hash_and_verification(self) -> None:
        password_hash = hash_password("sample-password")

        self.assertNotEqual(password_hash, "sample-password")
        self.assertTrue(verify_password("sample-password", password_hash))
        self.assertFalse(verify_password("wrong", password_hash))

    def test_access_token_round_trip(self) -> None:
        token = create_access_token(42)

        self.assertEqual(decode_access_token(token), 42)
        self.assertIsNone(decode_access_token(f"{token}broken"))


if __name__ == "__main__":
    unittest.main()
