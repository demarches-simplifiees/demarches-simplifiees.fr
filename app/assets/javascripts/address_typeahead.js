function address_type_init() {
  display = 'label';

  var bloodhound = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace(display),
    queryTokenizer: Bloodhound.tokenizers.whitespace,

    remote: {
      url: '/ban/search?request=%QUERY',
      wildcard: '%QUERY'
    }
  });
  bloodhound.initialize();

  $("input[type='address']").typeahead({
    minLength: 1
  }, {
    display: display,
    source: bloodhound,
    limit: 5
  });
}
