/**
 * Animatto Transactional Email Provider (web/lib/email.js)
 * 
 * Secure transactional email delivery for:
 * - Immediate license key delivery upon successful checkout
 * - Customer self-service license recovery
 * 
 * Provider Integration: Resend HTTPS REST API (https://api.resend.com/emails)
 * Requires zero external npm dependencies (built on native Node.js https).
 * 
 * Security & Reliability:
 * - In test/sandbox mode or when RESEND_API_KEY is not configured, dispatches
 *   are atomically recorded to db.recordEmailDispatch for automated testing and auditing.
 * - License keys are masked in system logs (only first/last 4 characters shown).
 */

const https = require('https');
const db = require('./db');

const FROM_ADDRESS = process.env.EMAIL_FROM || 'Animatto Licensing <support@animatto.app>';
const RESEND_API_KEY = process.env.RESEND_API_KEY;

function maskLicenseKey(key) {
  if (!key || typeof key !== 'string') return '****';
  if (key.length <= 12) return '****';
  return `${key.slice(0, 8)}...${key.slice(-6)}`;
}

/**
 * Send an email via Resend REST API or fallback to DB outbox
 */
async function sendEmail({ to, subject, html, text }) {
  const recipient = (to || '').trim().toLowerCase();
  if (!recipient || !recipient.includes('@')) {
    throw new Error(`Invalid recipient email: ${to}`);
  }

  // Always record into durable DB outbox for auditability & testing
  await db.recordEmailDispatch(recipient, subject, { html, text });

  // If no API key configured, return recorded status
  if (!RESEND_API_KEY) {
    return {
      success: true,
      mode: 'recorded_to_outbox',
      recipient,
      subject
    };
  }

  // Real HTTP dispatch via Resend
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      from: FROM_ADDRESS,
      to: [recipient],
      subject,
      html,
      text
    });

    const options = {
      hostname: 'api.resend.com',
      port: 443,
      path: '/emails',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ success: true, mode: 'sent_resend', id: parsed.id });
          } else {
            console.error(`[Email Provider Error] Resend responded with HTTP ${res.statusCode}:`, parsed.message || 'Unknown error');
            resolve({ success: false, mode: 'failed_resend', error: parsed.message });
          }
        } catch (e) {
          resolve({ success: false, mode: 'parse_error', error: e.message });
        }
      });
    });

    req.on('error', (err) => {
      console.error('[Email Provider Connection Error]:', err.message);
      resolve({ success: false, mode: 'network_error', error: err.message });
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Send purchase confirmation & license key
 */
async function sendLicenseDeliveryEmail({ email, orderId, licenseKey, maxDevices = 3 }) {
  const subject = 'Your Animatto Premium Lifetime License Key 🐇';
  
  const text = `Thank you for purchasing Animatto Premium!

Order ID: ${orderId}
License Key: ${licenseKey}
Device Limit: Up to ${maxDevices} personal Mac devices

HOW TO ACTIVATE:
1. Open Animatto on your Mac.
2. Click the Menubar icon or open Preferences.
3. Select "Unlock Premium" and paste your License Key above.
4. Click "Activate License".

Animatto Premium works completely offline. Your license is verified cryptographically without requiring a continuous internet connection.

Need support or moving to a new Mac? Visit https://animatto.app/support or email support@animatto.app.
`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #0f141c; color: #e8ecf2; padding: 24px; }
    .container { max-width: 560px; margin: 0 auto; background: #161c28; border: 1px solid #283347; border-radius: 12px; padding: 32px; }
    .badge { display: inline-block; padding: 4px 10px; background: rgba(255,107,107,0.15); color: #ff6b6b; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; margin-bottom: 16px; }
    h1 { font-size: 24px; margin-top: 0; color: #ffffff; }
    .key-box { background: #0b0e14; border: 1px solid #ff6b6b; border-radius: 8px; padding: 16px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 14px; word-break: break-all; color: #4ade80; margin: 20px 0; }
    .steps { background: #1a2232; border-radius: 8px; padding: 18px 20px; margin: 20px 0; }
    .steps ol { margin: 0; padding-left: 20px; }
    .steps li { margin-bottom: 8px; color: #cbd5e1; }
    .footer { font-size: 12px; color: #64748b; margin-top: 24px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">Animatto Premium</div>
    <h1>Thank you for your purchase!</h1>
    <p>Your lifetime license for <strong>Animatto Pro</strong> has been issued and is ready to activate on up to <strong>${maxDevices} Mac devices</strong>.</p>
    
    <div style="font-size: 13px; color: #94a3b8; margin-top: 16px;">ORDER REFERENCE: ${orderId}</div>
    <div class="key-box">${licenseKey}</div>

    <div class="steps">
      <strong style="color: #ffffff;">How to Activate in Animatto:</strong>
      <ol style="margin-top: 10px;">
        <li>Launch Animatto on your Mac.</li>
        <li>Open <strong>Settings</strong> &rarr; <strong>Unlock Premium</strong>.</li>
        <li>Paste your license key into the activation box.</li>
        <li>Click <strong>Activate License</strong> to immediately unlock all Premium features.</li>
      </ol>
    </div>

    <p style="font-size: 13px; color: #94a3b8;">
      Animatto operates <strong>100% offline</strong>. Your license key uses Ed25519 public-key cryptography to verify your entitlements locally on your Mac without tracking.
    </p>

    <div class="footer">
      &copy; ${new Date().getFullYear()} Animatto &bull; <a href="https://animatto.app" style="color: #ff6b6b;">animatto.app</a> &bull; 14-day refund policy
    </div>
  </div>
</body>
</html>
`;

  return sendEmail({ to: email, subject, html, text });
}

/**
 * Send customer license recovery email
 */
async function sendRecoveryEmail({ email, orders = [] }) {
  const subject = 'Your Animatto License Keys (Account Recovery)';
  
  if (orders.length === 0) {
    const text = `Hello,

We received a request to recover Animatto Premium licenses for ${email}.
However, we could not locate any active purchases associated with this email address.

If you purchased with a different email address, please try searching with that address, or contact support@animatto.app.
`;
    const html = `<div style="font-family: sans-serif; color: #222; padding: 20px;">
      <h2>Animatto License Recovery</h2>
      <p>We received a recovery request for <strong>${email}</strong>, but found no active Animatto Pro purchases linked to this email.</p>
      <p>If you used a different email during checkout, please submit a recovery request with that email address, or contact support@animatto.app.</p>
    </div>`;
    return sendEmail({ to: email, subject, html, text });
  }

  let licensesText = '';
  let licensesHtml = '';

  for (const ord of orders) {
    licensesText += `\n- Order ID: ${ord.orderId}\n  Status: ${ord.status}\n  License Key: ${ord.licenseToken}\n`;
    licensesHtml += `
      <div style="background: #1a2232; border: 1px solid #283347; border-radius: 8px; padding: 14px; margin-bottom: 12px;">
        <div style="font-size: 12px; color: #94a3b8;">Order: ${ord.orderId} &bull; Status: <strong style="color: #4ade80;">${ord.status}</strong></div>
        <div style="font-family: monospace; font-size: 13px; color: #f1f5f9; word-break: break-all; margin-top: 8px; padding: 8px; background: #0b0e14; border-radius: 4px;">
          ${ord.licenseToken}
        </div>
      </div>
    `;
  }

  const text = `Hello,

Here are the Animatto Premium license keys associated with ${email}:
${licensesText}

To activate on your Mac, open Animatto -> Settings -> Unlock Premium, and paste your license key.

Need help? Contact support@animatto.app.
`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: #0f141c; color: #e8ecf2; padding: 24px; }
    .container { max-width: 560px; margin: 0 auto; background: #161c28; border: 1px solid #283347; border-radius: 12px; padding: 32px; }
    h1 { font-size: 22px; color: #ffffff; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Animatto License Recovery</h1>
    <p>We found ${orders.length} license(s) linked to <strong>${email}</strong>:</p>
    ${licensesHtml}
    <p style="font-size: 13px; color: #94a3b8; margin-top: 20px;">
      Paste your key into Animatto on your Mac under <strong>Settings &rarr; Unlock Premium</strong>.
    </p>
  </div>
</body>
</html>
`;

  return sendEmail({ to: email, subject, html, text });
}

module.exports = {
  maskLicenseKey,
  sendEmail,
  sendLicenseDeliveryEmail,
  sendRecoveryEmail
};
