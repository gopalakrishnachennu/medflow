from fastapi.testclient import TestClient

from app.main import app


def test_health_endpoint():
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_ready_endpoint():
    with TestClient(app) as client:
        response = client.get("/ready")

    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_metrics_endpoint():
    with TestClient(app) as client:
        response = client.get("/metrics")

    assert response.status_code == 200
    assert "http_requests_total" in response.text


def test_register_and_login():
    payload = {
        "email": "doctor@example.com",
        "password": "StrongPass123",
        "role": "doctor",
    }

    with TestClient(app) as client:
        register_response = client.post("/auth/register", json=payload)
        assert register_response.status_code == 201
        assert register_response.json()["email"] == payload["email"]

        login_response = client.post(
            "/auth/login",
            json={"email": payload["email"], "password": payload["password"]},
        )
        assert login_response.status_code == 200
        assert login_response.json()["token_type"] == "bearer"
        assert login_response.json()["access_token"]
