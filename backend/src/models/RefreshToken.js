const mongoose = require('mongoose');

// A refresh token lets a client obtain a fresh, short-lived access token
// without re-entering credentials. The raw token is a high-entropy random
// string handed to the client; only its SHA-256 hash is stored here, so a
// database leak does not expose a usable token. Each token is single-use:
// presenting it mints a new pair and marks this one replaced (rotation), which
// makes a stolen-and-replayed token detectable and lets us revoke a whole
// session on logout.
const refreshTokenSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    // SHA-256 of the raw token. Never store the raw value.
    tokenHash: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    expiresAt: {
      type: Date,
      required: true,
    },
    // Set when the token is used (rotated) or explicitly revoked (logout).
    revokedAt: {
      type: Date,
      default: null,
    },
    // The hash of the token that superseded this one, for rotation auditing.
    replacedByHash: {
      type: String,
      default: null,
    },
    userAgent: { type: String, default: '' },
    ip: { type: String, default: '' },
  },
  { timestamps: true }
);

// Expired tokens are swept automatically by Mongo's TTL monitor.
refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

refreshTokenSchema.methods.isActive = function () {
  return !this.revokedAt && this.expiresAt.getTime() > Date.now();
};

module.exports = mongoose.model('RefreshToken', refreshTokenSchema);
