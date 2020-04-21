const activeRequests = new Set();

document.addEventListener('ajax:send', evt => {
  const [xhr] = evt.detail;
  activeRequests.add(xhr);
});

document.addEventListener('ajax:complete', evt => {
  const [xhr] = evt.detail;
  activeRequests.delete(xhr);
});

document.addEventListener('turbolinks:visit', () => {
  for (const xhr of activeRequests) {
    xhr.abort();
  }

  activeRequests.clear();
});
