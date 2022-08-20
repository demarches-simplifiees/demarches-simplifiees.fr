// For links and requests done through rails-ujs (mostly data-remote links),
// redirect to the sign-in page when the server responds '401 Unauthorized'.
document.addEventListener('ajax:error', (event) => {
  const [, , xhr] = event.detail;
  if (xhr && xhr.status == 401) {
    location.reload(); // reload whole page so Devise will redirect to sign-in
  }
});
