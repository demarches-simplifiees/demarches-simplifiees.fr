import autocomplete from 'autocomplete.js';
import { getJSON, fire } from '@utils';

const sources = [
  {
    type: 'address',
    url: '/address/suggestions'
  }
];

const options = {
  autoselect: true,
  minLength: 1
};

function selector(type) {
  return `[data-autocomplete=${type}]`;
}

function source(url) {
  return {
    source(query, callback) {
      getJSON(url, { request: query }).then(callback);
    },
    templates: {
      suggestion({ label, mine }) {
        const mineClass = `path-mine-${mine ? 'true' : 'false'}`;
        const openTag = `<div class="aa-suggestion ${mineClass}">`;
        return autocomplete.escapeHighlightedString(label, openTag, '</div>');
      }
    },
    debounce: 300
  };
}

addEventListener('ds:page:update', function() {
  for (let { type, url } of sources) {
    for (let element of document.querySelectorAll(selector(type))) {
      element.removeAttribute('data-autocomplete');
      autocompleteInitializeElement(element, url);
    }
  }
});

function autocompleteInitializeElement(element, url) {
  const select = autocomplete(element, options, [source(url)]);
  select.on('autocomplete:selected', ({ target }, suggestion) => {
    fire(target, 'autocomplete:select', suggestion);
    select.autocomplete.setVal(suggestion.label);
  });
}
