import { init, configureScope } from '@sentry/browser';
import { getData } from './data';

const { dsn, email, id } = getData('sentry');

if (dsn) {
  init({ dsn });

  if (email) {
    configureScope(scope => {
      scope.setUser({ id, email });
    });
  }
}
