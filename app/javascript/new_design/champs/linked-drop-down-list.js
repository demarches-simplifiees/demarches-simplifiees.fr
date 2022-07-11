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
function makeOption(option) {
  let element = document.createElement('option');
  element.textContent = option;
  element.value = option;
  return element;
}
function selectOptions(selectElement, options) {
  selectElement.innerHTML = '';
  if (selectElement.required) {
    selectElement.appendChild(makeOption(''));
  }
  for (let option of options) {
    selectElement.appendChild(makeOption(option));
  }

  selectElement.selectedIndex = 0;
}
