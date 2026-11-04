/**
 * Animatto Transactional Email Provider (web/lib/email.js)
 * 
 * Secure transactional email delivery for:
 * - Immediate license key delivery upon successful checkout
 * - Customer self-service license recovery
 * 
 * Provider Integration: Resend HTTPS REST API (https://api.resend.com/emails)
 * Built with native Node.js HTTPS (zero external runtime dependencies).
 * 
 * State Separation:
 * - 'queued': Recorded to persistent outbox prior to dispatch.
 * - 'sent': Successfully accepted by Resend with provider message ID.
 * - 'awaiting_retry': Transient network or 5xx server failure; awaiting retry attempt.
 * - 'failed': Permanent 4xx client rejection or max retries exceeded.
 */

const https = require('https');
const db = require('./db');

const FROM_ADDRESS = process.env.EMAIL_FROM || 'Animatto Licensing <support@animatto.app>';
const MAX_DISPATCH_RETRIES = 3;

// Mock HTTP transport hook for testing
let mockHttpTransport = null;

function setMockHttpTransport(transportFn) {
  mockHttpTransport = transportFn;
}

function maskLicenseKey(key) {
  if (!key || typeof key !== 'string') return '****';
  if (key.length <= 12) return '****';
  return `${key.slice(0, 8)}...${key.slice(-6)}`;
}

/**
 * Execute HTTP POST to Resend API
 */
function performResendHttpRequest(apiKey, postData) {
  if (mockHttpTransport) {
    return mockHttpTransport(apiKey, postData);
  }

  return new Promise((resolve) => {
    const options = {
      hostname: 'api.resend.com',
      port: 443,
      path: '/emails',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
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
          resolve({
            statusCode: res.statusCode,
            body: parsed
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode || 500,
            body: { message: `Malformed JSON response: ${e.message}` }
          });
        }
      });
    });

    req.on('error', (err) => {
      resolve({
        statusCode: 503,
        body: { message: `Network transport failure: ${err.message}` }
      });
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Send or Queue an email with clear state tracking
 */
async function sendEmail({ to, subject, html, text, orderId = null, messageType = 'license_delivery' }) {
  const recipient = (to || '').trim().toLowerCase();
  if (!recipient || !recipient.includes('@')) {
    throw new Error(`Invalid recipient email address: ${to}`);
  }

  // 1. Queue email in persistent database outbox
  const outboxId = await db.queueEmail({
    recipient,
    subject,
    content: { html, text },
    orderId,
    messageType
  });

  const apiKey = process.env.RESEND_API_KEY;

  // If no API key configured (development/sandbox without Resend):
  if (!apiKey && !mockHttpTransport) {
    return {
      success: true,
      status: 'queued',
      outboxId,
      message: 'Email queued in outbox (RESEND_API_KEY not configured)'
    };
  }

  // 2. Dispatch via Resend HTTP API
  const postData = JSON.stringify({
    from: FROM_ADDRESS,
    to: [recipient],
    subject,
    html,
    text
  });

  let attempt = 1;
  const res = await performResendHttpRequest(apiKey || 'mock_key', postData);

  if (res.statusCode >= 200 && res.statusCode < 300) {
    const resendId = res.body && res.body.id ? res.body.id : 'msg_mock_success';
    await db.updateEmailOutbox(outboxId, {
      status: 'sent',
      resendId,
      attempts: attempt,
      nextRetryAt: null
    });
    return {
      success: true,
      status: 'sent',
      resendId,
      outboxId
    };
  }

  // Handle errors
  const isTransient = res.statusCode >= 500 || res.statusCode === 429;
  const errorMsg = (res.body && res.body.message) || `HTTP error ${res.statusCode}`;

  if (isTransient && attempt < MAX_DISPATCH_RETRIES) {
    const delaySec = Math.min(3600, Math.pow(2, attempt) * 10);
    const nextRetryAt = new Date(Date.now() + delaySec * 1000);
    await db.updateEmailOutbox(outboxId, {
      status: 'awaiting_retry',
      lastError: errorMsg,
      attempts: attempt,
      nextRetryAt
    });
    return {
      success: false,
      status: 'awaiting_retry',
      error: errorMsg,
      outboxId,
      nextRetryAt
    };
  }

  await db.updateEmailOutbox(outboxId, {
    status: 'failed',
    lastError: errorMsg,
    attempts: attempt,
    nextRetryAt: null
  });
  return {
    success: false,
    status: 'failed',
    error: errorMsg,
    outboxId
  };
}

/**
 * Automatically process retries for emails in 'awaiting_retry' with exponential backoff
 */
async function processEmailOutboxRetries({ maxBatch = 10 } = {}) {
  const pending = await db.getEmailsAwaitingRetry(maxBatch);
  const results = [];

  for (const item of pending) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey && !mockHttpTransport) {
      results.push({ outboxId: item.id, status: 'awaiting_retry', message: 'No API key' });
      continue;
    }

    const postData = JSON.stringify({
      from: FROM_ADDRESS,
      to: [item.recipient],
      subject: item.subject,
      html: item.content?.html || '',
      text: item.content?.text || ''
    });

    const currentAttempt = (item.attempts || 0) + 1;
    const res = await performResendHttpRequest(apiKey || 'mock_key', postData);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      const resendId = res.body && res.body.id ? res.body.id : 'msg_mock_retry_success';
      await db.updateEmailOutbox(item.id, {
        status: 'sent',
        resendId,
        attempts: currentAttempt,
        nextRetryAt: null
      });
      results.push({ outboxId: item.id, status: 'sent', resendId, attempts: currentAttempt });
    } else {
      const isTransient = res.statusCode >= 500 || res.statusCode === 429;
      const errorMsg = res.body?.message || `HTTP ${res.statusCode}`;

      if (isTransient && currentAttempt < MAX_DISPATCH_RETRIES) {
        const delaySec = Math.min(3600, Math.pow(2, currentAttempt) * 10);
        const nextRetryAt = new Date(Date.now() + delaySec * 1000);
        await db.updateEmailOutbox(item.id, {
          status: 'awaiting_retry',
          lastError: errorMsg,
          attempts: currentAttempt,
          nextRetryAt
        });
        results.push({ outboxId: item.id, status: 'awaiting_retry', error: errorMsg, attempts: currentAttempt });
      } else {
        await db.updateEmailOutbox(item.id, {
          status: 'failed',
          lastError: errorMsg,
          attempts: currentAttempt,
          nextRetryAt: null
        });
        results.push({ outboxId: item.id, status: 'failed', error: errorMsg, attempts: currentAttempt });
      }
    }
  }

  const summary = {
    processed: results.length,
    succeeded: results.filter(r => r.status === 'sent').length,
    failed: results.filter(r => r.status === 'failed').length,
    awaitingRetry: results.filter(r => r.status === 'awaiting_retry').length,
    items: results
  };
  return Object.assign(results, summary);
}

/**
 * Retry an email that is in 'awaiting_retry' state
 */
async function retryEmail(outboxId, emailData) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey && !mockHttpTransport) {
    return { success: false, status: 'queued', error: 'No RESEND_API_KEY' };
  }

  const postData = JSON.stringify({
    from: FROM_ADDRESS,
    to: [emailData.recipient],
    subject: emailData.subject,
    html: emailData.content.html,
    text: emailData.content.text
  });

  const res = await performResendHttpRequest(apiKey || 'mock_key', postData);
  if (res.statusCode >= 200 && res.statusCode < 300) {
    const resendId = res.body && res.body.id ? res.body.id : 'msg_mock_retry_success';
    await db.updateEmailOutbox(outboxId, {
      status: 'sent',
      resendId,
      attempts: 2,
      nextRetryAt: null
    });
    return { success: true, status: 'sent', resendId, outboxId };
  }

  await db.updateEmailOutbox(outboxId, {
    status: 'failed',
    lastError: res.body?.message || `HTTP ${res.statusCode}`,
    attempts: 2,
    nextRetryAt: null
  });
  return { success: false, status: 'failed', error: res.body?.message, outboxId };
}

/**
 * Send purchase confirmation & license key
 */
async function sendLicenseDeliveryEmail({
  email: rawEmail,
  customerEmail,
  orderId,
  licenseKey: rawLicenseKey,
  licenseToken,
  maxDevices = 3,
  tier = 'pro'
}) {
  const email = rawEmail || customerEmail;
  const licenseKey = rawLicenseKey || licenseToken;

  // Prevent duplicate license delivery emails
  if (orderId) {
    const existing = await db.getEmailByOrderId(orderId, 'license_delivery');
    if (existing && (existing.status === 'sent' || existing.status === 'queued')) {
      return {
        success: true,
        duplicate: true,
        status: existing.status,
        outboxId: existing.id,
        resendId: existing.resendId
      };
    }
  }
  const isFounder = tier === 'founder';
  const tierName = isFounder ? 'Founder Supporter' : 'Lifetime Pro';
  const subject = isFounder
    ? 'Your Animatto Founder Supporter Lifetime License Key 💜'
    : 'Your Animatto Lifetime Pro License Key 🐇';
  
  const text = `Thank you for backing Animatto as a ${tierName}!

Order ID: ${orderId}
Tier: ${tierName}
License Key: ${licenseKey}
Device Limit: Up to ${maxDevices} personal Mac devices

HOW TO ACTIVATE:
1. Open Animatto on your Mac.
2. Click the Menubar icon or open Settings.
3. Select "Software Updates & Licensing" and paste your License Key above.
4. Click "Activate License".

Animatto licenses work completely offline. Your license is verified cryptographically without requiring a continuous internet connection.

Need support or moving to a new Mac? Visit https://animatto.app/support or email support@animatto.app.
`;

  const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f141c; color: #e8ecf2; padding: 24px; }
    .container { max-width: 560px; margin: 0 auto; background: #161c28; border: 1px solid #283347; border-radius: 12px; padding: 32px; }
    .badge { display: inline-block; padding: 4px 10px; background: rgba(168,85,247,0.15); color: #c084fc; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; margin-bottom: 16px; }
    h1 { font-size: 24px; margin-top: 0; color: #ffffff; }
    .key-box { background: #0b0e14; border: 1px solid #a855f7; border-radius: 8px; padding: 16px; font-family: ui-monospace, Menlo, monospace; font-size: 14px; word-break: break-all; color: #4ade80; margin: 20px 0; }
    .steps { background: #1a2232; border-radius: 8px; padding: 18px 20px; margin: 20px 0; }
    .steps ol { margin: 0; padding-left: 20px; }
    .steps li { margin-bottom: 8px; color: #cbd5e1; }
    .footer { font-size: 12px; color: #64748b; margin-top: 24px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">${tierName}</div>
    <h1>Thank you for your purchase!</h1>
    <p>Your lifetime license for <strong>${tierName}</strong> has been issued and is ready to activate on up to <strong>${maxDevices} Mac devices</strong>.</p>
    
    <div style="font-size: 13px; color: #94a3b8; margin-top: 16px;">ORDER REFERENCE: ${orderId}</div>
    <div class="key-box">${licenseKey}</div>

    <div class="steps">
      <strong style="color: #ffffff;">How to Activate in Animatto:</strong>
      <ol style="margin-top: 10px;">
        <li>Launch Animatto on your Mac.</li>
        <li>Open <strong>Settings</strong> &rarr; <strong>Software Updates & Licensing</strong>.</li>
        <li>Paste your license key into the activation box.</li>
        <li>Click <strong>Activate License</strong> to immediately unlock your entitlements.</li>
      </ol>
    </div>

    <p style="font-size: 13px; color: #94a3b8;">
      Animatto operates <strong>100% offline</strong>. Your license key uses Ed25519 public-key cryptography to verify your entitlements locally on your Mac without tracking.
    </p>

    <div class="footer">
      &copy; ${new Date().getFullYear()} Animatto &bull; <a href="https://animatto.app" style="color: #c084fc;">animatto.app</a>
    </div>
  </div>
</body>
</html>
`;

  return sendEmail({ to: email, subject, html, text, orderId, messageType: 'license_delivery' });
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
    return sendEmail({ to: email, subject, html, text, messageType: 'recovery' });
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
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f141c; color: #e8ecf2; padding: 24px; }
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

  return sendEmail({ to: email, subject, html, text, messageType: 'recovery' });
}

module.exports = {
  maskLicenseKey,
  sendEmail,
  retryEmail,
  processEmailOutboxRetries,
  sendLicenseDeliveryEmail,
  sendRecoveryEmail,
  setMockHttpTransport
};
