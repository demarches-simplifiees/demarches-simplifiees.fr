import { delegate } from '@utils';

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
}

delegate('input', '#procedure-edit #procedure_libelle', syncFormToPreview);
delegate('input', '#procedure-edit #procedure_description', syncFormToPreview);

