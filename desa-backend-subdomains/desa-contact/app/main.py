import os
import smtplib
from email.message import EmailMessage

from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse

app = FastAPI()

SMTP_HOST = os.getenv("SMTP_HOST", "relay3.sansa.org.za")
SMTP_PORT = int(os.getenv("SMTP_PORT", "25"))
MAIL_FROM = os.getenv("MAIL_FROM", "desa@sansa.org.za")
MAIL_TO = os.getenv("MAIL_TO", "desa@sansa.org.za")


@app.post("/api/contact", response_class=HTMLResponse)
def submit_contact(
    first_name: str = Form(...),
    last_name: str = Form(...),
    email: str = Form(...),
    enquiry_type: str = Form(...),
    message: str = Form(...),
):
    full_name = f"{first_name} {last_name}".strip()

    msg = EmailMessage()
    msg["Subject"] = f"DESA Contact Form - {enquiry_type}"
    msg["From"] = MAIL_FROM
    msg["To"] = MAIL_TO
    msg["Reply-To"] = email

    msg.set_content(
        f"""
New DESA website enquiry

Name: {full_name}
Email: {email}
Enquiry type: {enquiry_type}

Message:
{message}
""".strip()
    )

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=20) as smtp:
            smtp.send_message(msg)
    except Exception as exc:
        print(f"Email send failed: {exc}")

        return HTMLResponse(
            content="""
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Unable to send enquiry | DESA</title>

                <style>
                    * {
                        box-sizing: border-box;
                    }

                    body {
                        margin: 0;
                        min-height: 100vh;
                        font-family: "Segoe UI", Arial, sans-serif;
                        background: #ffffff;
                        color: #0b2a57;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }

                    .error-container {
                        width: 100%;
                        padding: 40px 20px;
                        text-align: center;
                    }

                    .error-card {
                        max-width: 650px;
                        margin: 0 auto;
                    }

                    .error-icon {
                        width: 110px;
                        height: 110px;
                        margin: 0 auto 30px;
                        border-radius: 50%;
                        background: #fdebed;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                    }

                    .envelope {
                        position: relative;
                        width: 55px;
                        height: 40px;
                        border: 4px solid #c7353e;
                        border-radius: 5px;
                    }

                    .envelope::before {
                        content: "";
                        position: absolute;
                        width: 32px;
                        height: 32px;
                        border-left: 4px solid #c7353e;
                        border-bottom: 4px solid #c7353e;
                        transform: rotate(-45deg);
                        top: -17px;
                        left: 7px;
                    }

                    .alert {
                        position: absolute;
                        right: -18px;
                        bottom: -18px;
                        width: 34px;
                        height: 34px;
                        border-radius: 50%;
                        background: #c7353e;
                        color: white;
                        border: 3px solid #fdebed;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-size: 20px;
                        font-weight: 700;
                    }

                    h1 {
                        margin: 0 0 18px;
                        font-size: 42px;
                        line-height: 1.15;
                        color: #0b2a57;
                    }

                    .subtitle {
                        margin: 0 0 12px;
                        font-size: 22px;
                        color: #667085;
                    }

                    .message {
                        max-width: 500px;
                        margin: 0 auto 32px;
                        font-size: 16px;
                        line-height: 1.6;
                        color: #7a8493;
                    }

                    .return-button {
                        display: inline-block;
                        padding: 15px 30px;
                        background: #0b3b75;
                        color: #ffffff;
                        text-decoration: none;
                        border-radius: 8px;
                        font-size: 16px;
                        font-weight: 600;
                        transition: background 0.2s ease,
                                    transform 0.2s ease;
                    }

                    .return-button:hover {
                        background: #082d59;
                        transform: translateY(-1px);
                    }

                    .arrow {
                        margin-right: 9px;
                        font-size: 20px;
                    }

                    @media (max-width: 600px) {
                        h1 {
                            font-size: 32px;
                        }

                        .subtitle {
                            font-size: 19px;
                        }

                        .error-icon {
                            width: 95px;
                            height: 95px;
                        }
                    }
                </style>
            </head>

            <body>

                <main class="error-container">
                    <div class="error-card">

                        <div class="error-icon">
                            <div class="envelope">
                                <div class="alert">!</div>
                            </div>
                        </div>

                        <h1>Unable to send enquiry</h1>

                        <p class="subtitle">
                            Please try again later.
                        </p>

                        <p class="message">
                            We are currently unable to send your message.
                            If the problem persists, please try again in a few minutes.
                        </p>

                        <a href="/contact" class="return-button">
                            <span class="arrow">&larr;</span>
                            Return to Contact Us
                        </a>

                    </div>
                </main>

            </body>
            </html>
            """,
            status_code=502,
        )
