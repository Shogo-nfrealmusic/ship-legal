import httpx

from app.config import MAILGUN_API_KEY


def send_promo(to: str, name: str) -> None:
    """Weekly promo blast."""
    httpx.post(
        "https://api.mailgun.net/v3/mg.printpal.example/messages",
        auth=("api", MAILGUN_API_KEY),
        data={
            "from": "PrintPal <deals@printpal.example>",
            "to": to,
            "subject": "40% off canvas prints this weekend only!",
            "html": f"<p>Hi {name},</p><p>All canvas prints are 40% off until Sunday. <a href='https://printpal.example'>Order now</a></p>",
        },
    )
