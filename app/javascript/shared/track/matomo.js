const { key, enabled } = gon.matomo || {};

if (enabled) {
  window._paq = window._paq || [];

  const url = '//stats.data.gouv.fr/';
  const trackerUrl = `${url}piwik.php`;
  const jsUrl = `${url}piwik.js`;

  // Configure Matomo analytics
  window._paq.push(['setCookieDomain', '*.www.demarches-simplifiees.fr']);
  window._paq.push(['setDomains', ['*.www.demarches-simplifiees.fr']]);
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

  // Send Matomo a new event when navigating to a new page using Turbolinks
  // (see https://developer.matomo.org/guides/spa-tracking)
  let previousPageUrl = null;
  addEventListener('turbolinks:load', event => {
    if (previousPageUrl) {
      window._paq.push(['setReferrerUrl', previousPageUrl]);
      window._paq.push(['setCustomUrl', window.location.href]);
      window._paq.push(['setDocumentTitle', document.title]);
      if (event.data && event.data.timing) {
        window._paq.push([
          'setGenerationTimeMs',
          event.data.timing.visitEnd - event.data.timing.visitStart
        ]);
      }
      window._paq.push(['trackPageView']);
    }
    previousPageUrl = window.location.href;
  });
}
