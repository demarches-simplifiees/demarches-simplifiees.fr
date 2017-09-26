document.addEventListener('turbolinks:load', function() {
  $('select.select2').select2();

  $('select.select2-limited').select2({
    'placeholder': 'Sélectionnez des colonnes',
    'maximumSelectionLength': '2',
    'width': '300px'
  });
});
