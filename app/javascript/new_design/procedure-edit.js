import { show, hide, delegate } from '@utils';

function syncInputToElement(fromSelector, toSelector) {
  const fromElement = document.querySelector(fromSelector);
  const toElement = document.querySelector(toSelector);
  if (toElement && fromElement) {
    toElement.innerText = fromElement.value;
  }
}

function syncFormToPreview() {
  syncInputToElement('#procedure_libelle', 'h2.procedure-title');
  syncInputToElement('#procedure_description', '.procedure-description-body');

  const euroFlagCheckbox = document.querySelector('#procedure_euro_flag');
  const euroFlagLogo = document.querySelector('#euro_flag');
  if (euroFlagCheckbox && euroFlagLogo) {
    euroFlagCheckbox.checked ? show(euroFlagLogo) : hide(euroFlagLogo);
  }
}

delegate('input', '#procedure-edit #procedure_libelle', syncFormToPreview);
delegate('input', '#procedure-edit #procedure_description', syncFormToPreview);
delegate('change', '#procedure-edit #procedure_euro_flag', syncFormToPreview);
