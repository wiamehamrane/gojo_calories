const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const nodemailer = require("nodemailer");

// Sensitive values → Firebase secrets (set with `firebase functions:secrets:set`).
const SMTP_USER = defineSecret("SMTP_USER");
const SMTP_PASS = defineSecret("SMTP_PASS");
// Shared secret the backend must send in the `x-otp-secret` header.
const OTP_SHARED_SECRET = defineSecret("OTP_SHARED_SECRET");

// Non-sensitive values come from functions/.env (SMTP_HOST, SMTP_PORT, SMTP_FROM).

/**
 * POST { email, code }  (header: x-otp-secret)
 * Sends the 6-digit verification code email. The backend still generates and
 * verifies the code — this function only delivers the email.
 */
exports.sendOtpEmail = onRequest(
  {
    secrets: [SMTP_USER, SMTP_PASS, OTP_SHARED_SECRET],
    region: "us-central1",
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({error: "method_not_allowed"});
      return;
    }
    if (req.get("x-otp-secret") !== OTP_SHARED_SECRET.value()) {
      res.status(401).json({error: "unauthorized"});
      return;
    }

    const {email, code} = req.body || {};
    if (!email || !code) {
      res.status(400).json({error: "email_and_code_required"});
      return;
    }

    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || "587", 10);
    const from = process.env.SMTP_FROM ||
      "GojoCalories <noreply@gojocalories.com>";

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: port === 465,
      auth: {user: SMTP_USER.value(), pass: SMTP_PASS.value()},
    });

    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #007D8F;">Verify your email</h2>
        <p>Enter this code in the app to verify your GojoCalories account:</p>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #007D8F;">${code}</p>
        <p style="color: #666; font-size: 14px;">This code expires in 15 minutes. If you didn't create an account, you can ignore this email.</p>
      </div>`;

    try {
      await transporter.sendMail({
        from,
        to: email,
        subject: "Your GojoCalories verification code",
        html,
      });
      logger.info("OTP email sent", {email});
      res.status(200).json({ok: true});
    } catch (e) {
      logger.error("OTP email failed", e);
      res.status(502).json({error: "send_failed"});
    }
  },
);
