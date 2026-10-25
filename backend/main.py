import os
import secrets
from typing import Optional
from fastapi import Request
import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI(title="HerON Emergency Alert API")

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
API_KEY = os.getenv("HERON_API_KEY", "")


class AlertRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=200)

    trusted_contact_chat_ids: list[str] = Field(
        default_factory=list,
        max_length=10,
    )

    latitude: Optional[float] = Field(
        default=None,
        ge=-90,
        le=90,
    )

    longitude: Optional[float] = Field(
        default=None,
        ge=-180,
        le=180,
    )


@app.get("/")
async def home():
    return {
        "service": "HerON Emergency Alert API",
        "status": "running",
    }


@app.post("/alert")
async def send_alert(
    alert: AlertRequest,
    x_api_key: str = Header(default=""),
):
    # Authenticate the app's request.
    if not API_KEY or not secrets.compare_digest(x_api_key, API_KEY):
        raise HTTPException(
            status_code=401,
            detail="Unauthorized",
        )

    if not BOT_TOKEN:
        raise HTTPException(
            status_code=503,
            detail="Telegram bot token is missing",
        )

    # Remove empty IDs and duplicate recipients.
    recipients = list(
        dict.fromkeys(
            chat_id.strip()
            for chat_id in alert.trusted_contact_chat_ids
            if chat_id.strip()
        )
    )

    if not recipients:
        raise HTTPException(
            status_code=400,
            detail="No trusted contacts with linked Telegram accounts",
        )

    message = (
        "🚨 HERON SAFETY ALERT\n\n"
        f"Reason: {alert.reason}\n\n"
        "Please contact the user and verify their safety."
    )

    if alert.latitude is not None and alert.longitude is not None:
        message += (
            "\n\nLast reported location: "
            f"https://maps.google.com/?q="
            f"{alert.latitude},{alert.longitude}"
        )

    results = []

    async with httpx.AsyncClient(timeout=15.0) as client:
        for chat_id in recipients:
            try:
                response = await client.post(
                    f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
                    json={
                        "chat_id": chat_id,
                        "text": message,
                    },
                )

                data = response.json()

                if response.is_success and data.get("ok"):
                    results.append({
                        "recipient": chat_id,
                        "status": "sent",
                    })
                else:
                    print(
                        "Telegram API error:",
                        data.get("description", "Unknown error"),
                    )
                    results.append({
                        "recipient": chat_id,
                        "status": "failed",
                    })

            except (httpx.HTTPError, ValueError) as error:
                print("Telegram request failed:", str(error))
                results.append({
                    "recipient": chat_id,
                    "status": "failed",
                })

    succeeded = sum(
        result["status"] == "sent"
        for result in results
    )

    if succeeded == 0:
        raise HTTPException(
            status_code=502,
            detail="Could not deliver the alert to any trusted contact",
        )

    return {
        "status": "sent" if succeeded == len(results) else "partial",
        "successful_deliveries": succeeded,
        "total_recipients": len(results),
        "results": results,
    }
@app.post("/telegram-webhook")
async def telegram_webhook(request: Request):
    update = await request.json()

    message = update.get("message", {})
    chat = message.get("chat", {})
    text = message.get("text", "")

    if text.startswith("/start") and chat.get("id") is not None:
        chat_id = chat["id"]

        reply = (
            "Welcome to HerON! 🛡️\n\n"
            "Your Telegram Chat ID is:\n"
            f"`{chat_id}`\n\n"
            "Share this ID with the person adding you "
            "as a trusted contact in HerON."
        )

        async with httpx.AsyncClient(timeout=15.0) as client:
            await client.post(
                f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage",
                json={
                    "chat_id": chat_id,
                    "text": reply,
                },
            )

    return {"ok": True}