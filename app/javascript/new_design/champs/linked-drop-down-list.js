import { delegate } from '@utils';

const PRIMARY_SELECTOR = 'select[data-secondary-options]';
const SECONDARY_SELECTOR = 'select[data-secondary]';
const CHAMP_SELECTOR = '.editable-champ';

delegate('change', PRIMARY_SELECTOR, (evt) => {
  const primary = evt.target;
  const secondary = primary
    .closest(CHAMP_SELECTOR)
    .querySelector(SECONDARY_SELECTOR);
  const options = JSON.parse(primary.dataset.secondaryOptions);

  selectOptions(secondary, options[primary.value]);
});

function selectOptions(selectElement, options) {
  selectElement.innerHTML = '';

  for (let option of options) {
    let element = document.createElement('option');
    element.textContent = option;
    element.value = option;
    selectElement.appendChild(element);
  }

  selectElement.selectedIndex = 0;
}
