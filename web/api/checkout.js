/**
 * Animatto Checkout API Endpoint (/api/checkout)
 * 
 * Creates a Dodo Payments hosted checkout session for Animatto Premium ($9.99 USD).
 * Supports both direct browser GET (redirect) and client POST (returns JSON checkout_url).
 */

const https = require('https');

// Rate limiting map (in-memory for serverless edge)
const rateLimitMap = new Map();

function isRateLimited(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute
  const maxRequests = 20;

  const userRecord = rateLimitMap.get(ip) || [];
  const validRequests = userRecord.filter(time => now - time < windowMs);

  if (validRequests.length >= maxRequests) {
    return true;
  }

  validRequests.push(now);
  rateLimitMap.set(ip, validRequests);
  return false;
}

module.exports = async function handler(req, res) {
  // CORS & Security Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  if (isRateLimited(clientIp)) {
    return res.status(429).json({ error: 'Too many requests. Please wait a moment.' });
  }

  const apiKey = process.env.DODO_PAYMENTS_API_KEY;
  const productId = process.env.DODO_PAYMENTS_PRODUCT_ID || 'pdt_animatto_premium_lifetime';
  const mode = process.env.DODO_PAYMENTS_MODE || 'test';
  const host = mode === 'live' ? 'live.dodopayments.com' : 'test.dodopayments.com';

  const customerEmail = (req.body && req.body.customerEmail) || req.query.customerEmail || '';
  const returnUrl = (req.body && req.body.returnUrl) || req.query.returnUrl || 'https://animatto.app/success';

  // If no production/sandbox API key is configured in the environment:
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
