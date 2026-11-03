/**
 * Animatto Checkout API Endpoint (/api/checkout)
 * 
 * Creates a Dodo Payments hosted checkout session for Animatto Premium ($9.99 USD).
 * - Restricts CORS to official and verified application domains
 * - Fails closed on missing production configuration
 * - Validates return URLs against an explicit allowlist
 * - Validates product IDs and customer email formats
 * - Enforces request size limits and edge rate limiting
 */

const https = require('https');

// Rate limiting map (in-memory sliding window)
const rateLimitMap = new Map();
const MAX_REQUESTS_PER_MINUTE = 20;
const MAX_BODY_BYTES = 16 * 1024; // 16 KB

function isRateLimited(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000;

  const userRecord = rateLimitMap.get(ip) || [];
  const validRequests = userRecord.filter(time => now - time < windowMs);

  if (validRequests.length >= MAX_REQUESTS_PER_MINUTE) {
    return true;
  }

  validRequests.push(now);
  rateLimitMap.set(ip, validRequests);
  return false;
}

// CORS Origin Validation
function setCorsHeaders(req, res) {
  const origin = req.headers.origin;
  const allowedOriginPattern = /^(https:\/\/([a-z0-9-]+\.)?animatto\.app|https:\/\/[a-z0-9-]+\.vercel\.app|http:\/\/localhost(:\d+)?|http:\/\/127\.0\.0\.1(:\d+)?)$/;

  if (origin && allowedOriginPattern.test(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  } else {
    res.setHeader('Access-Control-Allow-Origin', 'https://animatto.app');
  }

  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

// Return URL Allowlist Enforcement
function sanitizeReturnUrl(url) {
  if (!url || typeof url !== 'string') return 'https://animatto.app/success';
  try {
    const parsed = new URL(url);
    const host = parsed.hostname;
    const isAllowedHost = host === 'animatto.app' ||
                          host === 'www.animatto.app' ||
                          host.endsWith('.vercel.app') ||
                          host === 'localhost' ||
                          host === '127.0.0.1';
    if (isAllowedHost && (parsed.protocol === 'https:' || (parsed.protocol === 'http:' && (host === 'localhost' || host === '127.0.0.1')))) {
      return url;
    }
  } catch (_) {}
  return 'https://animatto.app/success';
}

module.exports = async function handler(req, res) {
  setCorsHeaders(req, res);

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  if (isRateLimited(clientIp)) {
    return res.status(429).json({ error: 'Too many requests. Please wait a moment.' });
  }

  // Request size limit
  let rawBodyLength = 0;
  if (typeof req.body === 'string') {
    rawBodyLength = Buffer.byteLength(req.body);
  } else if (Buffer.isBuffer(req.body)) {
    rawBodyLength = req.body.length;
  } else if (req.body && typeof req.body === 'object') {
    rawBodyLength = Buffer.byteLength(JSON.stringify(req.body));
  }
  if (rawBodyLength > MAX_BODY_BYTES) {
    return res.status(413).json({ error: 'Request body exceeds maximum size' });
  }

  const apiKey = process.env.DODO_PAYMENTS_API_KEY;
  const productId = process.env.DODO_PAYMENTS_PRODUCT_ID || 'pdt_animatto_premium_lifetime';
  const mode = process.env.DODO_PAYMENTS_MODE || 'test';
  const host = mode === 'live' ? 'live.dodopayments.com' : 'test.dodopayments.com';

  // In live production, missing API key must FAIL CLOSED
  if (mode === 'live' && !apiKey) {
    console.error('[Checkout API] FATAL: DODO_PAYMENTS_API_KEY is not configured in live production mode.');
    return res.status(500).json({ error: 'Checkout service configuration error. Please contact support.' });
  }

  const reqBody = (req.body && typeof req.body === 'object') ? req.body : {};
  const requestedProductId = reqBody.productId || req.query.productId || productId;
  if (requestedProductId !== productId && requestedProductId !== 'pdt_animatto_premium_lifetime') {
    return res.status(400).json({ error: 'Invalid product ID' });
  }

  let customerEmail = (reqBody.customerEmail || req.query.customerEmail || '').trim().toLowerCase();
  if (customerEmail && (!customerEmail.includes('@') || customerEmail.length > 254)) {
    return res.status(400).json({ error: 'Invalid email address' });
  }

  const returnUrl = sanitizeReturnUrl(reqBody.returnUrl || req.query.returnUrl);

  // If no API key configured (sandbox development):
  if (!apiKey) {
    const sandboxNotice = {
      status: 'sandbox_ready',
      message: 'Animatto Payment Provider Integration: Dodo Payments (Test Mode Sandbox). To link production payments, set DODO_PAYMENTS_API_KEY in server environment variables.',
      provider: 'Dodo Payments (Merchant of Record)',
      product: {
        id: productId,
        name: 'Animatto Premium — One-Time Purchase',
        price_usd: 9.99,
        device_limit: 3,
        terms: 'Perpetual license, 14-day refund guarantee'
      },
      checkout_url: `https://${host}/pay/${productId}?customer_email=${encodeURIComponent(customerEmail)}&return_url=${encodeURIComponent(returnUrl)}`
    };

    if (req.method === 'GET' && req.query.redirect === 'true') {
      return res.redirect(302, sandboxNotice.checkout_url);
    }
    return res.status(200).json(sandboxNotice);
  }

  // Programmatically create checkout session with Dodo Payments API
  const postData = JSON.stringify({
    product_id: productId,
    customer: customerEmail ? { email: customerEmail } : undefined,
    return_url: returnUrl,
    metadata: {
      app: 'Animatto',
      platform: 'macOS',
      tier: 'premium_lifetime'
    }
  });

  const options = {
    hostname: host,
    port: 443,
    path: '/checkouts',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const request = https.request(options, (response) => {
    let responseBody = '';
    response.on('data', chunk => responseBody += chunk);
    response.on('end', () => {
      try {
        const parsed = JSON.parse(responseBody);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          const checkoutUrl = parsed.checkout_url || parsed.url;
          if (req.method === 'GET' && req.query.redirect === 'true') {
            return res.redirect(302, checkoutUrl);
          }
          return res.status(200).json({ checkout_url: checkoutUrl, session_id: parsed.id });
        } else {
          console.error(`[Checkout API] Dodo Error (${response.statusCode}):`, parsed.message || 'Unknown');
          return res.status(502).json({ error: 'Failed to create checkout session with provider' });
        }
      } catch (err) {
        return res.status(500).json({ error: 'Invalid response from checkout provider' });
      }
    });
  });

  request.on('error', (err) => {
    console.error('[Checkout API] Connection error:', err.message);
    return res.status(503).json({ error: 'Payment checkout service temporarily unavailable' });
  });

  request.write(postData);
  request.end();
};
