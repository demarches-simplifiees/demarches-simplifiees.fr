import $ from 'jquery';
import 'select2';

const optionTemplate = email =>
  $(
    '<span class="custom-select2-option"><span class="icon person"></span>' +
      email.text +
      '</span>'
  );

addEventListener('ds:page:update', () => {
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

  $('select.select2-limited.select-instructeurs').select2({
    language: 'fr',
    dropdownParent: $('.instructeur-wrapper'),
    placeholder: 'Saisir l’adresse email de l’instructeur',
    tags: true,
    tokenSeparators: [',', ' '],
    templateResult: optionTemplate,
    templateSelection: function(email) {
      return $(
        '<span class="custom-select2-option"><span class="icon person"></span>' +
          email.text +
          '</span>'
      );
    }
  });
});
