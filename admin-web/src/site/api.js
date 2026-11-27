import axios from 'axios';

/**
 * The public site talks to the API through its own axios instance.
 *
 * The dashboard client attaches the admin token and bounces to /login on a
 * 401 — neither of which belongs on a page a visitor is reading, so the two
 * are kept apart deliberately.
 */
const publicApi = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api',
  headers: { 'Content-Type': 'application/json' },
});

const messageFrom = (error, fallback) =>
  error?.response?.data?.message ||
  (error?.response ? fallback : 'We could not reach the server. Please check your connection and try again.');

export const joinNotifyList = async ({ email, phone, platform }) => {
  try {
    const { data } = await publicApi.post('/leads/notify', { email, phone, platform });
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, message: messageFrom(error, 'We could not add you to the list just now.') };
  }
};

export const sendContactMessage = async (payload) => {
  try {
    const { data } = await publicApi.post('/leads/contact', payload);
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, message: messageFrom(error, 'We could not send your message just now.') };
  }
};

export default publicApi;
