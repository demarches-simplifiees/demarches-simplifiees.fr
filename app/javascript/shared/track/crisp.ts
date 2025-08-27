import { getConfig } from '@utils';
const {
  crisp: { websiteId, enabled, administrateur },
  locale
} = getConfig();

declare const window: Window &
  typeof globalThis & {
    CRISP_WEBSITE_ID?: string | null;
    CRISP_RUNTIME_CONFIG?: {
      locale: string;
    };
    $crisp: (
      | [cmd: string, key: string, value: unknown]
      | [key: string, value: unknown]
    )[];
  };

if (enabled) {
  window.$crisp = [];
  window.CRISP_WEBSITE_ID = websiteId;
  window.CRISP_RUNTIME_CONFIG = {
    locale: locale
  };

  const script = document.createElement('script');
  const firstScript = document.getElementsByTagName('script')[0];
  script.type = 'text/javascript';
  script.id = 'crisp-js';
  script.async = true;
  script.src = 'https://client.crisp.chat/l.js';
  firstScript.parentNode?.insertBefore(script, firstScript);

  window.$crisp.push(['set', 'user:email', [administrateur.email]]);
  window.$crisp.push(['set', 'session:segments', [['administrateur']]]);
  window.$crisp.push(['set', 'session:data']);

  // Prevent Crisp to log warnings about Sentry overriding document.addEventListener
  window.$crisp.push(['safe', true]);
}
