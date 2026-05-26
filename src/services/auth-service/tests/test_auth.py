from jose import jwt

from app.auth import create_access_token, hash_password, verify_password
from app.config import settings


def test_password_hash_and_verify():
    hashed_password = hash_password("StrongPass123")

    assert hashed_password != "StrongPass123"
    assert verify_password("StrongPass123", hashed_password)


def test_create_access_token_contains_subject_and_role():
    token = create_access_token(subject="patient@example.com", role="patient")
    payload = jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])

    assert payload["sub"] == "patient@example.com"
    assert payload["role"] == "patient"

