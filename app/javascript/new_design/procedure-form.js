import { delegate } from '@utils';

function syncInputToElement(fromSelector, toSelector) {
  const fromElement = document.querySelector(fromSelector);
  const toElement = document.querySelector(toSelector);
  if (toElement && fromElement) {
    toElement.innerText = fromElement.value;
  }
}

function syncFormToPreview() {
  syncInputToElement('#procedure_libelle', '.procedure-title');
  syncInputToElement('#procedure_description', '.procedure-description-body');
  syncInputToElement('#procedure_description_what', '.js_description_what p');
  syncInputToElement(
    '#procedure_description_for_who',
    '.js_description_for_who p'
  );
}

delegate('input', '.procedure-form #procedure_libelle', syncFormToPreview);
delegate('input', '.procedure-form #procedure_description', syncFormToPreview);
delegate(
  'input',
  '.procedure-form #procedure_description_what',
  syncFormToPreview
);
delegate(
  'input',
  '.procedure-form #procedure_description_for_who',
  syncFormToPreview
);
