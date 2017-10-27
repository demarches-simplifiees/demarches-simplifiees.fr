document.addEventListener('turbolinks:load', function() {
  $('select.select2').select2({
    'language': 'fr'
  });

  $('select.select2-limited').select2({
    'language': 'fr',
    'placeholder': 'Sélectionnez des colonnes',
    'maximumSelectionLength': '5',
    'width': '300px'
  });
});
