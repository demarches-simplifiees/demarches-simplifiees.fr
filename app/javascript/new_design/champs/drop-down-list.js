import { delegate, show, hide } from '@utils';

delegate(
  'change',
  '.editable-champ-drop_down_list select, .editable-champ-drop_down_list input[type="radio"]',
  (event) => {
    const parent = event.target.closest('.editable-champ-drop_down_list');
    const inputGroup = parent?.querySelector('.drop_down_other');
    if (inputGroup) {
      const input = inputGroup.querySelector('input');
      if (event.target.value === '__other__') {
        show(inputGroup);
        input.disabled = false;
      } else {
        hide(inputGroup);
        input.disabled = true;
      }
    }
  }
);
