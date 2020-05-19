import * as Sentry from '@sentry/browser';

const { key, enabled, user, environment, browser } = gon.sentry || {};

// We need to check for key presence here as we do not have a dsn for browser yet
if (enabled && key) {
  Sentry.init({ dsn: key, environment });

  Sentry.configureScope((scope) => {
    scope.setUser(user);
    scope.setExtra('browser', browser.modern ? 'modern' : 'legacy');
  });

  // Register a way to explicitely capture messages from a different bundle.
  addEventListener('sentry:capture-exception', (event) => {
    const error = event.detail;
    Sentry.captureException(error);
  });
}
