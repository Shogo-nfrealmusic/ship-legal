import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent.parent / "printpal.db"


def conn() -> sqlite3.Connection:
    c = sqlite3.connect(DB_PATH)
    c.row_factory = sqlite3.Row
    c.executescript(
        """
        create table if not exists users (id integer primary key, email text unique, password_hash text, name text);
        create table if not exists orders (id integer primary key, user_id integer, artwork text, size text,
            card_number text, card_expiry text, card_cvc text, total_cents integer);
        """
    )
    return c
