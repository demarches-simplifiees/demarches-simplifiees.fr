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
          'URL_MANAGER',
          'https://www.demarches-simplifiees.fr/manager/administrateurs/' +
            administrateur.DS_ID
        ]
      ]
    ]
  ]);
}
