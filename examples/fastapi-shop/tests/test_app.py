from fastapi.testclient import TestClient

import app.main as main


def test_home_renders(monkeypatch):
    client = TestClient(main.app)
    r = client.get("/")
    assert r.status_code == 200
    assert "Order print" in r.text


def test_signup_redirects(monkeypatch, tmp_path):
    monkeypatch.setattr(main, "send_promo", lambda *a, **k: None)
    monkeypatch.setattr("app.db.DB_PATH", tmp_path / "t.db")
    client = TestClient(main.app)
    r = client.post("/signup", data={"email": "a@example.com", "password": "pw123456", "name": "A"}, follow_redirects=False)
    assert r.status_code == 303
