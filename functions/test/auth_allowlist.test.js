const test = require('node:test');
const assert = require('node:assert/strict');

const { isAllowedEmail, normalizeAllowedEmails } = require('../auth_allowlist');

test('allowlist matching is case-insensitive and trims addresses', () => {
  const allowed = normalizeAllowedEmails(' Rafid@Example.com , jannat@example.com ');
  assert.deepEqual(allowed, ['rafid@example.com', 'jannat@example.com']);
  assert.equal(isAllowedEmail(' RAFID@example.com ', allowed), true);
});

test('unlisted or absent addresses are rejected for both creation and sign-in', () => {
  const allowed = normalizeAllowedEmails('rafid@example.com,jannat@example.com');
  assert.equal(isAllowedEmail('other@example.com', allowed), false);
  assert.equal(isAllowedEmail(undefined, allowed), false);
});

test('empty allowlist rejects every account', () => {
  assert.equal(isAllowedEmail('rafid@example.com', normalizeAllowedEmails(' , ')), false);
});
