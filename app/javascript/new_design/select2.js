import $ from 'jquery';
import 'select2';

addEventListener('turbolinks:load', () => {
  $('select.select2').select2({
    language: 'fr',
    width: '100%'
  });

  $('.columns-form select.select2-limited').select2({
    language: 'fr',
    placeholder: 'Sélectionnez des colonnes',
    maximumSelectionLength: '5',
    width: '300px'
  });

  $('.recipients-form select.select2-limited').select2({
    language: 'fr',
    placeholder: 'Sélectionnez des instructeurs',
    maximumSelectionLength: '30',
    width: '300px'
  });
});
