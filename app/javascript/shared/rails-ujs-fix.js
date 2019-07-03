import Rails from '@rails/ujs';
import jQuery from 'jquery';
import { delegate } from '@utils';

// We use `jQuery.active` in our capybara suit to wait for ajax requests.
// Newer jQuery-less version of rails-ujs is breaking it.
// We have to set `ajax:complete` listener on the same element as the one
// we catch ajax:send on as by the end of the request
// the old element may be removed from DOM.
delegate('ajax:send', '[data-remote]', ({ target }) => {
  let callback = () => {
    jQuery.active--;
    target.removeEventListener('ajax:complete', callback);
  };
  target.addEventListener('ajax:complete', callback);
  jQuery.active++;
});

// `smart_listing` gem is overriding `$.rails.href` method. When using newer
// jQuery-less version of rails-ujs it breaks.
// https://github.com/Sology/smart_listing/blob/master/app/assets/javascripts/smart_listing.coffee.erb#L9
addEventListener('load', () => {
  const { href, handleRemote } = Rails;
  Rails.href = function(element) {
    return element.href || href(element);
  };
  Rails.handleRemote = function(e) {
    if (this instanceof HTMLElement) {
      handleRemote.call(this, e);
    } else {
      let element = e.find('[data-remote]')[0];
      let event = new CustomEvent('click');
      Object.defineProperty(event, 'target', { value: element });
      return handleRemote.call(element, event);
    }
  };
});

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
