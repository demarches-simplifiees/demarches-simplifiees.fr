const { key, enabled, administrateur } = gon.sendinblue || {};

if (enabled) {
  window.sib = {
    equeue: [],
    client_key: key,
    email_id: administrateur.email
  };

  const script = document.createElement('script');
  const firstScript = document.getElementsByTagName('script')[0];
  script.type = 'text/javascript';
  script.id = 'sendinblue-js';
  script.async = true;
  script.src = `https://sibautomation.com/sa.js?key=${window.sib.client_key}`;
  firstScript.parentNode.insertBefore(script, firstScript);

  window.sib.equeue.push({ page: [] });
  window.sib.equeue.push({
    identify: [administrateur.email, administrateur.payload]
  });
}
