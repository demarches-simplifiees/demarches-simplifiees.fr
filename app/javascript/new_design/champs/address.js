import Bloodhound from 'bloodhound-js';

const display = 'label';

const bloodhound = new Bloodhound({
  datumTokenizer: Bloodhound.tokenizers.obj.whitespace(display),
  queryTokenizer: Bloodhound.tokenizers.whitespace,

  remote: {
    url: '/ban/search?request=%QUERY',
    wildcard: '%QUERY'
  }
});

bloodhound.initialize();

function bindTypeahead() {
  $('input[data-address="true"]').typeahead(
    {
      minLength: 1
    },
    {
      display: display,
      source: bloodhound,
      limit: 5
    }
  );
}

addEventListener('turbolinks:load', bindTypeahead);
