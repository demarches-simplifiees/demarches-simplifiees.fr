const { key, enabled } = gon.matomo || {};

if (enabled) {
  window._paq = window._paq || [];

  const url = 'https://beta.mes-demarches.gov.pf/matomo/';
  const trackerUrl = `${url}piwik.php`;
  const jsUrl = `${url}piwik.js`;

  // Configure Matomo analytics
  window._paq.push(['setCookieDomain', '*.mes-demarches.gov.pf']);
  window._paq.push(['setDomains', ['*.mes-demarches.gov.pf']]);
  window._paq.push(['setDoNotTrack', true]);
  window._paq.push(['trackPageView']);
  window._paq.push(['enableLinkTracking']);

  // Load script from Matomo
  window._paq.push(['setTrackerUrl', trackerUrl]);
  window._paq.push(['setSiteId', key]);

  const script = document.createElement('script');
  const firstScript = document.getElementsByTagName('script')[0];
  script.type = 'text/javascript';
  script.id = 'matomo-js';
  script.async = true;
  script.src = jsUrl;
  firstScript.parentNode.insertBefore(script, firstScript);
}
