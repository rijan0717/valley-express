const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const RefreshToken = require('../models/RefreshToken');

// The development fallback is a value committed to this repository, so any
// token signed with it can be forged by anyone who has read the source —
// including one claiming the admin role. It is therefore allowed only outside
// production, where a real secret must be supplied.
const DEV_SECRET = 'super_secret_jwt_key_valley_express_2026';

const secret = () => {
  if (process.env.JWT_SECRET) return process.env.JWT_SECRET;
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'JWT_SECRET must be set in production. Refusing to sign tokens with the public development key.'
    );
  }
  return DEV_SECRET;
};

// Access tokens are now short-lived. A stolen access token is only useful until
// it expires, and the client silently renews it with its refresh token. The
// window is configurable but defaults to one hour (was 30 days).
const ACCESS_TTL = process.env.JWT_EXPIRES_IN || '1h';

// Refresh tokens live much longer (default 30 days) but can be revoked server
// side at any time, unlike a bare JWT.
const REFRESH_TTL_MS =
  (Number(process.env.REFRESH_TOKEN_DAYS) || 30) * 24 * 60 * 60 * 1000;

const generateToken = (id, role) => {
  return jwt.sign({ id, role }, secret(), { expiresIn: ACCESS_TTL });
};

// Raw refresh token: 48 random bytes, URL-safe. Only its hash is persisted.
const newRefreshRaw = () => crypto.randomBytes(48).toString('base64url');
const hashRefresh = (raw) => crypto.createHash('sha256').update(raw).digest('hex');

// Issue a brand-new session: a short access token plus a fresh refresh token
// recorded (hashed) in the database.
const issueSession = async (user, req = {}) => {
  const token = generateToken(user._id, user.role);
  const raw = newRefreshRaw();
  await RefreshToken.create({
    user: user._id,
    tokenHash: hashRefresh(raw),
    expiresAt: new Date(Date.now() + REFRESH_TTL_MS),
    userAgent: (req.headers && req.headers['user-agent']) || '',
    ip: (req.headers && req.headers['x-forwarded-for']) || req.ip || '',
  });
  return { token, refreshToken: raw };
};

// Exchange a presented refresh token for a new pair, rotating the old one.
// Returns null when the token is unknown, expired or already used/revoked.
const rotateSession = async (rawRefresh, req = {}) => {
  if (!rawRefresh) return null;
  const tokenHash = hashRefresh(rawRefresh);
  const existing = await RefreshToken.findOne({ tokenHash }).populate('user');
  if (!existing || !existing.isActive() || !existing.user) {
    return null;
  }
  const user = existing.user;
  const token = generateToken(user._id, user.role);
  const raw = newRefreshRaw();
  const newHash = hashRefresh(raw);
  await RefreshToken.create({
    user: user._id,
    tokenHash: newHash,
    expiresAt: new Date(Date.now() + REFRESH_TTL_MS),
    userAgent: (req.headers && req.headers['user-agent']) || '',
    ip: (req.headers && req.headers['x-forwarded-for']) || req.ip || '',
  });
  existing.revokedAt = new Date();
  existing.replacedByHash = newHash;
  await existing.save();
  return { token, refreshToken: raw, user };
};

// Revoke a single refresh token (logout on this device).
const revokeSession = async (rawRefresh) => {
  if (!rawRefresh) return;
  await RefreshToken.updateOne(
    { tokenHash: hashRefresh(rawRefresh), revokedAt: null },
    { revokedAt: new Date() }
  );
};

// Revoke every active refresh token for a user (logout everywhere / on
// suspension or password change).
const revokeAllSessions = async (userId) => {
  await RefreshToken.updateMany(
    { user: userId, revokedAt: null },
    { revokedAt: new Date() }
  );
};

module.exports = {
  generateToken,
  secret,
  issueSession,
  rotateSession,
  revokeSession,
  revokeAllSessions,
};
