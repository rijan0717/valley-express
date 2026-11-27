// Server-side confirmation that an online payment really happened.
//
// The client must never be the source of truth for "paid": it can be scripted
// to POST whatever it likes. We confirm every online payment directly with the
// gateway, using the identifier the gateway itself issued, and only accept it
// when the gateway reports the transaction complete AND the amount matches the
// order total.
//
// These are the documented eSewa EPAY v2 and Khalti e-Payment endpoints; no
// endpoint or field here is invented. When the gateway cannot be reached, or
// the identifiers are missing, verification fails closed (returns verified:
// false) rather than assuming success.

const ESEWA_STATUS_URL =
  process.env.ESEWA_STATUS_URL ||
  'https://rc-epay.esewa.com.np/api/epay/transaction/status/';
const ESEWA_MERCHANT_CODE = process.env.ESEWA_MERCHANT_CODE || 'EPAYTEST';

const KHALTI_LOOKUP_URL =
  process.env.KHALTI_LOOKUP_URL || 'https://a.khalti.com/api/v2/epayment/lookup/';
const KHALTI_SECRET_KEY =
  process.env.KHALTI_SECRET_KEY || 'test_secret_key_f59e8b7d18b4499f8286f809f30997cb';

const withTimeout = async (fn, ms = 7000) => {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), ms);
  try {
    return await fn(controller.signal);
  } finally {
    clearTimeout(t);
  }
};

// eSewa: GET status by product_code + total_amount + transaction_uuid.
// A complete payment returns { status: 'COMPLETE', total_amount, ... }.
const verifyEsewa = async ({ transactionUuid, totalAmount }) => {
  if (!transactionUuid) return { verified: false, reason: 'missing transaction_uuid' };
  try {
    const url =
      `${ESEWA_STATUS_URL}?product_code=${encodeURIComponent(ESEWA_MERCHANT_CODE)}` +
      `&total_amount=${encodeURIComponent(totalAmount)}` +
      `&transaction_uuid=${encodeURIComponent(transactionUuid)}`;
    const data = await withTimeout(async (signal) => {
      const r = await fetch(url, { signal });
      return r.json();
    });
    const paid =
      data &&
      String(data.status).toUpperCase() === 'COMPLETE' &&
      Number(data.total_amount) >= Number(totalAmount);
    return {
      verified: Boolean(paid),
      reference: data?.ref_id || transactionUuid,
      reason: paid ? 'complete' : `gateway status ${data?.status}`,
    };
  } catch (e) {
    return { verified: false, reason: `esewa lookup failed: ${e.message}` };
  }
};

// Khalti: POST { pidx } with the secret key; a complete payment returns
// { status: 'Completed', total_amount (paisa), ... }.
const verifyKhalti = async ({ pidx, totalAmount }) => {
  if (!pidx) return { verified: false, reason: 'missing pidx' };
  try {
    const data = await withTimeout(async (signal) => {
      const r = await fetch(KHALTI_LOOKUP_URL, {
        method: 'POST',
        headers: {
          Authorization: `Key ${KHALTI_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ pidx }),
        signal,
      });
      return r.json();
    });
    const paid =
      data &&
      String(data.status) === 'Completed' &&
      Number(data.total_amount) >= Math.round(Number(totalAmount) * 100);
    return {
      verified: Boolean(paid),
      reference: data?.transaction_id || pidx,
      reason: paid ? 'completed' : `gateway status ${data?.status}`,
    };
  } catch (e) {
    return { verified: false, reason: `khalti lookup failed: ${e.message}` };
  }
};

// method -> verifier. Unknown/offline methods are never "verified" here.
const verifyGatewayPayment = async (method, params) => {
  if (method === 'esewa') return verifyEsewa(params);
  if (method === 'khalti') return verifyKhalti(params);
  return { verified: false, reason: `no server-side verification for ${method}` };
};

module.exports = { verifyGatewayPayment, verifyEsewa, verifyKhalti };
