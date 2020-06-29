const { key, enabled, administrateur } = gon.crisp || {};

if (enabled) {
  window.$crisp = [];
  window.CRISP_WEBSITE_ID = key;

  const script = document.createElement('script');
  const firstScript = document.getElementsByTagName('script')[0];
  script.type = 'text/javascript';
  script.id = 'crisp-js';
  script.async = true;
  script.src = 'https://client.crisp.chat/l.js';
  firstScript.parentNode.insertBefore(script, firstScript);

  window.$crisp.push(['set', 'user:email', [administrateur.email]]);
  window.$crisp.push(['set', 'session:segments', [['administrateur']]]);
  window.$crisp.push([
    'set',
    'session:data',
    [
      [
        ['DS_ID', administrateur.email],
        ['DS_SIGN_IN_COUNT', administrateur.DS_SIGN_IN_COUNT],
        [
          'DS_NB_DEMARCHES_BROUILLONS',
          administrateur.DS_NB_DEMARCHES_BROUILLONS
        ],
        ['DS_NB_DEMARCHES_ACTIVES', administrateur.DS_NB_DEMARCHES_ACTIVES],
        ['DS_NB_DEMARCHES_ARCHIVES', administrateur.DS_NB_DEMARCHES_ARCHIVES],
        [
          'URL_MANAGER',
          'https://www.demarches-simplifiees.fr/manager/administrateurs/' +
            administrateur.DS_ID
        ]
      ]
    ]
  ]);
  window.$crisp.push([
    'set',
    'session:event',
    [[['PAGE_VIEW', { URL: window.location.pathname }]]]
  ]);

  // Prevent Crisp to log warnings about Sentry overriding document.addEventListener
  window.$crisp.push(['safe', true]);
}
