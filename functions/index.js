const {
  beforeUserCreated,
  beforeUserSignedIn,
} = require('firebase-functions/v2/identity');
const { HttpsError } = require('firebase-functions/v2/https');
const { defineString } = require('firebase-functions/params');
const { isAllowedEmail, normalizeAllowedEmails } = require('./auth_allowlist');

const allowedEmailsParameter = defineString('LIFE_OS_ALLOWED_EMAILS');

const requireAllowedEmail = (event) => {
  const email = event.data.email?.trim().toLowerCase();
  const allowedEmails = normalizeAllowedEmails(allowedEmailsParameter.value());

  if (!isAllowedEmail(email, allowedEmails)) {
    throw new HttpsError(
      'permission-denied',
      'LIFE OS accounts are provisioned for invited users only.',
    );
  }

  return {};
};

exports.restrictAccountCreation = beforeUserCreated(requireAllowedEmail);
exports.restrictSignIn = beforeUserSignedIn(requireAllowedEmail);
