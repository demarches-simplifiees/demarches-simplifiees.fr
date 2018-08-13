import Rails from 'rails-ujs';
import jQuery from 'jquery';

// We use `jQuery.active` in our capybara suit to wait for ajax requests.
// Newer jQuery-less version of rails-ujs is breaking it.
// We have to set `ajax:complete` listener on the same element as the one
// we catch ajax:send on as by the end of the request
// the old element may be removed from DOM.
Rails.delegate(document, '[data-remote]', 'ajax:send', ({ target }) => {
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
  const { href } = Rails;
  Rails.href = function(element) {
    return element.href || href(element);
  };
});
