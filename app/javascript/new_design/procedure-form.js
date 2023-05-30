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
  syncInputToElement('#procedure_description', '.js_description p');
  syncInputToElement(
    '#procedure_description_target_audience',
    '.js_description_target_audience p'
  );
}

delegate('input', '.procedure-form #procedure_libelle', syncFormToPreview);
delegate('input', '.procedure-form #procedure_description', syncFormToPreview);
delegate(
  'input',
  '.procedure-form #procedure_description_target_audience',
  syncFormToPreview
);
