import autocomplete from 'autocomplete.js';
import { getJSON, fire } from '@utils';

const sources = [
  {
    type: 'address',
    url: '/ban/search'
  },
  {
    type: 'path',
    url: '/admin/procedures/path_list'
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

addEventListener('turbolinks:load', function() {
  for (let { type, url } of sources) {
    for (let target of document.querySelectorAll(selector(type))) {
      let select = autocomplete(target, options, [source(url)]);
      select.on('autocomplete:selected', ({ target }, suggestion) => {
        fire(target, 'autocomplete:select', suggestion);
        select.autocomplete.setVal(suggestion.label);
      });
    }
  }
});
