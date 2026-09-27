import hashlib
from pathlib import Path

from fastapi import FastAPI, File, Form, Request, UploadFile
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.db import conn
from app.emailer import send_promo

BASE = Path(__file__).resolve().parent
UPLOADS = BASE.parent / "uploads"
UPLOADS.mkdir(exist_ok=True)

app = FastAPI(title="PrintPal")
app.mount("/static", StaticFiles(directory=BASE / "static"), name="static")
app.mount("/uploads", StaticFiles(directory=UPLOADS), name="uploads")
templates = Jinja2Templates(directory=BASE / "templates")

PRICES = {"small": 1900, "large": 3900}
SERVICE_FEE_CENTS = 499


def hash_pw(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(request, "index.html", {"prices": PRICES})


@app.get("/signup", response_class=HTMLResponse)
def signup_form(request: Request):
    return templates.TemplateResponse(request, "signup.html")


@app.post("/signup")
def signup(email: str = Form(...), password: str = Form(...), name: str = Form("")):
    c = conn()
    c.execute("insert into users (email, password_hash, name) values (?, ?, ?)", (email, hash_pw(password), name))
    c.commit()
    send_promo(email, name)
    return RedirectResponse("/", status_code=303)


@app.post("/login")
def login(email: str = Form(...), password: str = Form(...)):
    row = conn().execute("select * from users where email = ? and password_hash = ?", (email, hash_pw(password))).fetchone()
    if not row:
        return HTMLResponse("Wrong email or password", status_code=401)
    return RedirectResponse("/", status_code=303)


@app.post("/order")
async def order(
    artwork: UploadFile = File(...),
    size: str = Form(...),
    card_number: str = Form(...),
    card_expiry: str = Form(...),
    card_cvc: str = Form(...),
):
    dest = UPLOADS / artwork.filename
    dest.write_bytes(await artwork.read())
    total = PRICES[size] + SERVICE_FEE_CENTS
    c = conn()
    c.execute(
        "insert into orders (artwork, size, card_number, card_expiry, card_cvc, total_cents) values (?, ?, ?, ?, ?, ?)",
        (artwork.filename, size, card_number, card_expiry, card_cvc, total),
    )
    c.commit()
    return RedirectResponse(f"/gallery?new={artwork.filename}", status_code=303)


@app.get("/gallery", response_class=HTMLResponse)
def gallery(request: Request):
    files = sorted(p.name for p in UPLOADS.iterdir())
    return templates.TemplateResponse(request, "gallery.html", {"files": files})


@app.get("/admin/orders")
def admin_orders():
    rows = conn().execute("select * from orders").fetchall()
    return [dict(r) for r in rows]
