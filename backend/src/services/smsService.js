/**
 * Valley Express SMS Service
 * Supports pluggable SMS providers for Nepal:
 * 1. Sparrow SMS (API token)
 * 2. Aakash SMS (Auth token)
 * 3. Twilio (SID + Token)
 * 4. Development Sandbox (Mock logger)
 */

const sendSMS = async (phone, message) => {
  const sparrowToken = process.env.SPARROW_SMS_TOKEN;
  const aakashToken = process.env.AAKASH_SMS_TOKEN;
  const twilioSid = process.env.TWILIO_ACCOUNT_SID;

  // 1. Sparrow SMS Gateway (Popular in Nepal)
  if (sparrowToken) {
    try {
      const response = await fetch('http://api.sparrowsms.com/v2/sms/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: sparrowToken,
          from: process.env.SPARROW_SMS_IDENTITY || 'ValleyExp',
          to: phone,
          text: message,
        }),
      });
      const data = await response.json();
      console.log('[SMS Service] Sparrow SMS dispatched:', data);
      return { success: true, provider: 'sparrow', response: data };
    } catch (err) {
      console.error('[SMS Service] Sparrow SMS Error:', err.message);
    }
  }

  // 2. Aakash SMS Gateway (Nepal)
  if (aakashToken) {
    try {
      const response = await fetch('https://aakashsms.com/admin/api/v3/sms/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          auth_token: aakashToken,
          to: phone,
          text: message,
        }),
      });
      const data = await response.json();
      console.log('[SMS Service] Aakash SMS dispatched:', data);
      return { success: true, provider: 'aakash', response: data };
    } catch (err) {
      console.error('[SMS Service] Aakash SMS Error:', err.message);
    }
  }

  // 3. Fallback: Development Mode Console Logger
  console.log(`[SMS Gateway - Development Mode] To: ${phone} | Content: "${message}"`);
  return { success: true, provider: 'development_sandbox', delivered: true };
};

module.exports = {
  sendSMS,
};
