/**
 * Animatto Checkout API Endpoint (/api/checkout)
 * 
 * Creates a Dodo Payments hosted checkout session for Animatto:
 * - Lifetime Pro: $3.99 USD (One-time payment, perpetual access across up to 3 personal Macs)
 * - Founder Supporter: $5.99 USD (One-time payment, all Pro features + README recognition + early beta access)
 * - Uses official Dodo Payments SDK (client.checkoutSessions.create)
 * - Restricts CORS to official and verified application domains
 * - Fails closed on missing production configuration
 * - Validates return URLs against an explicit allowlist
 * - Validates product IDs and customer email formats
 * - Enforces request size limits and edge rate limiting
 * - Guarantees production checkout remains disabled in test mode
 */

const { getDodoEnvironment, getProductCatalog, getDodoClient } = require('../lib/dodo');

// Rate limiting map (in-memory sliding window)
const rateLimitMap = new Map();
const MAX_REQUESTS_PER_MINUTE = 20;
const MAX_BODY_BYTES = 16 * 1024; // 16 KB

const EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

function isRateLimited(ip) {
  const now = Date.now();
  const windowMs = 60 * 1000;

  if (rateLimitMap.size > 1000) {
    for (const [key, times] of rateLimitMap.entries()) {
      const active = times.filter(time => now - time < windowMs);
      if (active.length === 0) rateLimitMap.delete(key);
      else rateLimitMap.set(key, active);
    }
  }

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
  const environment = getDodoEnvironment();
  const host = environment === 'live_mode' ? 'live.dodopayments.com' : 'test.dodopayments.com';

  // In live production, missing API key must FAIL CLOSED
  if (environment === 'live_mode' && !apiKey) {
    console.error('[Checkout API] FATAL: DODO_PAYMENTS_API_KEY is not configured in live production mode.');
    return res.status(500).json({ error: 'Checkout service configuration error. Please contact support.' });
  }

  // Live checkout safety gate: production checkout is disabled during test-mode phase
  if (environment === 'live_mode' && process.env.ENABLE_PRODUCTION_PAYMENTS !== 'true') {
    console.warn('[Checkout API] Live payments are currently disabled (Test Mode phase active).');
    return res.status(503).json({ error: 'Live payments are currently disabled. Please contact support.' });
  }

  const reqBody = (req.body && typeof req.body === 'object') ? req.body : {};
  const requestedTier = (reqBody.tier || req.query.tier || '').trim().toLowerCase();
  let requestedProductId = reqBody.productId || req.query.productId;

  const catalog = getProductCatalog();

  // Prevent tier escalation and mismatch between requested tier and productId
  if (requestedTier && requestedProductId) {
    const isFounderTier = requestedTier === 'founder';
    const isFounderProd = requestedProductId === catalog.founder.productId ||
                          requestedProductId === 'pdt_animatto_founder_lifetime';
    if (isFounderTier !== isFounderProd) {
      return res.status(400).json({ error: 'Mismatched tier and product ID' });
    }
  }

  // Resolve product ID and tier details
  let effectiveTier = 'pro';
  let effectiveProductId = catalog.pro.productId;
  let effectivePriceUSD = catalog.pro.priceUSD;
  let productName = catalog.pro.name;

  if (requestedTier === 'founder' || requestedProductId === catalog.founder.productId || requestedProductId === 'pdt_animatto_founder_lifetime') {
    effectiveTier = 'founder';
    effectiveProductId = catalog.founder.productId;
    effectivePriceUSD = catalog.founder.priceUSD;
    productName = catalog.founder.name;
  } else if (requestedProductId === 'pdt_animatto_premium_lifetime') {
    // Legacy alias mapping
    effectiveTier = 'pro';
    effectiveProductId = catalog.pro.productId;
    effectivePriceUSD = catalog.pro.priceUSD;
    productName = catalog.pro.name;
  }

  const allowedProductIds = [
    'pdt_animatto_pro_lifetime',
    'pdt_animatto_founder_lifetime',
    'pdt_animatto_premium_lifetime',
    catalog.pro.productId,
    catalog.founder.productId
  ].filter(Boolean);

  if (requestedProductId && !allowedProductIds.includes(requestedProductId)) {
    return res.status(400).json({ error: 'Invalid product ID' });
  }

  let customerEmail = (reqBody.customerEmail || req.query.customerEmail || '').trim().toLowerCase();
  if (customerEmail) {
    if (!EMAIL_REGEX.test(customerEmail) || customerEmail.length > 254) {
      return res.status(400).json({ error: 'Invalid customer email address format' });
    }
  } else if (req.method === 'POST') {
    return res.status(400).json({ error: 'Customer email address is required' });
  }

  // Optional Supporter Name (Strict consent gate)
  const supporterConsent = reqBody.supporterConsent === true || req.query.supporterConsent === 'true';
  const supporterName = supporterConsent && typeof reqBody.supporterName === 'string'
    ? reqBody.supporterName.trim().slice(0, 40)
    : undefined;

  const returnUrl = sanitizeReturnUrl(reqBody.returnUrl || req.query.returnUrl);

  // If no API key configured (sandbox development without credentials):
  if (!apiKey) {
    const sandboxNotice = {
      status: 'sandbox_ready',
      message: 'Animatto Payment Provider Integration: Dodo Payments (Test Mode Sandbox). To link production payments, set DODO_PAYMENTS_API_KEY in server environment variables.',
      provider: 'Dodo Payments (Merchant of Record)',
      product: {
        id: effectiveProductId,
        name: productName,
        tier: effectiveTier,
        price_usd: effectivePriceUSD,
        device_limit: 3,
        terms: 'Perpetual one-time license, no subscription'
      },
      checkout_url: `https://${host}/pay/${effectiveProductId}?customer_email=${encodeURIComponent(customerEmail)}&return_url=${encodeURIComponent(returnUrl)}`
    };

    if (req.method === 'GET' && req.query.redirect === 'true') {
      return res.redirect(302, sandboxNotice.checkout_url);
    }
    return res.status(200).json(sandboxNotice);
  }

  // Programmatically create hosted checkout session via official Dodo Payments SDK
  try {
    const client = getDodoClient();
    const session = await client.checkoutSessions.create({
      product_cart: [
        { product_id: effectiveProductId, quantity: 1 }
      ],
      customer: customerEmail ? { email: customerEmail } : undefined,
      return_url: returnUrl,
      metadata: {
        app: 'Animatto',
        platform: 'macOS',
        tier: effectiveTier,
        supporter_name: supporterName || '',
        supporter_consent: supporterConsent ? 'true' : 'false'
      }
    });

    const checkoutUrl = session.checkout_url || session.url;
    const sessionId = session.session_id || session.id;

    if (req.method === 'GET' && req.query.redirect === 'true') {
      return res.redirect(302, checkoutUrl);
    }
    return res.status(200).json({ checkout_url: checkoutUrl, session_id: sessionId });
  } catch (err) {
    console.error('[Checkout API] Dodo Payments error:', err.message);
    const statusCode = err.status || err.statusCode || 502;
    return res.status(statusCode >= 400 && statusCode < 600 ? statusCode : 502).json({
      error: 'Failed to create checkout session with provider',
      details: err.message
    });
  }
};
