import jQuery from 'jquery';

// rails-ujs installs CSRFProtection for its own ajax implementation. We might need
// CSRFProtection for jQuery initiated requests. This code is from jquery-ujs.
jQuery.ajaxPrefilter((options, originalOptions, xhr) => {
  if (!options.crossDomain) {
    CSRFProtection(xhr);
  }
});

function csrfToken() {
  return jQuery('meta[name=csrf-token]').attr('content');
}

function CSRFProtection(xhr) {
  let token = csrfToken();
  if (token) {
    xhr.setRequestHeader('X-CSRF-Token', token);
  }
}
