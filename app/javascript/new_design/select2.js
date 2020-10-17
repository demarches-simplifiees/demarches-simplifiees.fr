import $ from 'jquery';
import 'select2';

const language = {
  errorLoading: function () {
    return 'Les résultats ne peuvent pas être chargés.';
  },
  inputTooLong: function (args) {
    var overChars = args.input.length - args.maximum;

    return 'Supprimez ' + overChars + ' caractère' + (overChars > 1 ? 's' : '');
  },
  inputTooShort: function (args) {
    var remainingChars = args.minimum - args.input.length;

    return (
      'Saisissez au moins ' +
      remainingChars +
      ' caractère' +
      (remainingChars > 1 ? 's' : '')
    );
  },
  loadingMore: function () {
    return 'Chargement de résultats supplémentaires…';
  },
  maximumSelected: function (args) {
    return (
      'Vous pouvez seulement sélectionner ' +
      args.maximum +
      ' élément' +
      (args.maximum > 1 ? 's' : '')
    );
  },
  noResults: function () {
    return 'Aucun résultat trouvé';
  },
  searching: function () {
    return 'Recherche en cours…';
  },
  removeAllItems: function () {
    return 'Supprimer tous les éléments';
  }
};

const baseOptions = {
  language,
  width: '100%'
};

const templateOption = ({ text }) =>
  $(
    `<span class="custom-select2-option"><span class="icon person"></span>${text}</span>`
  );

addEventListener('ds:page:update', () => {
  $('select.select2').select2(baseOptions);

  $('.columns-form select.select2-limited').select2({
    width: '300px',
    placeholder: 'Sélectionnez des colonnes',
    maximumSelectionLength: '5'
  });

  $('.recipients-form select.select2-limited').select2({
    language,
    width: '300px',
    placeholder: 'Sélectionnez des instructeurs',
    maximumSelectionLength: '30'
  });

  $('select.select2-limited.select-instructeurs').select2({
    language,
    dropdownParent: $('.instructeur-wrapper'),
    placeholder: 'Saisir l’adresse email de l’instructeur',
    tags: true,
    tokenSeparators: [',', ' '],
    templateResult: templateOption,
    templateSelection: templateOption
  });
});
