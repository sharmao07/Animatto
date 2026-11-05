/**
 * Official Dodo Payments Client & Product Catalog (web/lib/dodo.js)
 * 
 * Provides centralized initialization and access to the official Dodo Payments SDK:
 * - Hosted Checkout Sessions (client.checkoutSessions.create)
 * - Standard Webhooks verification (client.webhooks.unwrap)
 * - Safe environment normalization (defaults strictly to 'test_mode')
 * - Product allowlist and exact price constants ($3.99 Pro, $5.99 Founder)
 * - Test mode mock client hook for deterministic automated testing
 */

const DodoPayments = require('dodopayments');

/**
 * Normalizes environment safely to 'test_mode' or 'live_mode'.
 * Missing, empty, or unrecognized values default safely to 'test_mode'.
 */
function getDodoEnvironment() {
  const env = (process.env.DODO_PAYMENTS_ENVIRONMENT || '').trim().toLowerCase();
  const mode = (process.env.DODO_PAYMENTS_MODE || '').trim().toLowerCase();

  if (env === 'live_mode' || env === 'live' || mode === 'live') {
    return 'live_mode';
  }
  return 'test_mode';
}

/**
 * Product catalog constants and environment overrides
 */
function getProductCatalog() {
  const proId = process.env.DODO_PAYMENTS_PRO_PRODUCT_ID || 'pdt_animatto_pro_lifetime';
  const founderId = process.env.DODO_PAYMENTS_FOUNDER_PRODUCT_ID || 'pdt_animatto_founder_lifetime';

  return {
    pro: {
      productId: proId,
      name: 'Animatto Lifetime Pro — One-Time Purchase',
      priceCents: 399,
      priceUSD: 3.99,
      tier: 'pro'
    },
    founder: {
      productId: founderId,
      name: 'Animatto Founder Supporter — One-Time Purchase',
      priceCents: 599,
      priceUSD: 5.99,
      tier: 'founder'
    }
  };
}

let mockDodoClient = null;

function setMockDodoClient(client) {
  mockDodoClient = client;
}

function getDodoClient() {
  if (mockDodoClient) {
    return mockDodoClient;
  }

  const apiKey = process.env.DODO_PAYMENTS_API_KEY;
  const webhookKey = process.env.DODO_PAYMENTS_WEBHOOK_KEY || process.env.DODO_PAYMENTS_WEBHOOK_SECRET;
  const environment = getDodoEnvironment();

  return new DodoPayments({
    bearerToken: apiKey,
    webhookKey: webhookKey,
    environment: environment
  });
}

module.exports = {
  getDodoEnvironment,
  getProductCatalog,
  getDodoClient,
  setMockDodoClient
};
