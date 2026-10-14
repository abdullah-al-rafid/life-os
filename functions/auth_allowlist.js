function normalizeAllowedEmails(value) {
  return value
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

function isAllowedEmail(email, allowedEmails) {
  return typeof email === 'string' && allowedEmails.includes(email.trim().toLowerCase());
}

module.exports = { isAllowedEmail, normalizeAllowedEmails };
