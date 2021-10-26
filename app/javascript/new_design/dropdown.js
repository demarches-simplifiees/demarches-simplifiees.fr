import { delegate } from '@utils';

delegate('click', 'body', (event) => {
  if (!event.target.closest('.dropdown, [data-reach-combobox-popover]')) {
    [...document.querySelectorAll('.dropdown')].forEach((element) => {
      const button = element.querySelector('.dropdown-button');
      button.setAttribute('aria-expanded', false);
      element.classList.remove('open', 'fade-in-down');
    });
  }
});

delegate('click', '.dropdown-button', (event) => {
  event.stopPropagation();
  const button = event.target.closest('.dropdown-button');
  const parent = button.parentElement;
  if (parent.classList.contains('dropdown')) {
    parent.classList.toggle('open');
    var buttonExpanded = button.getAttribute('aria-expanded') === 'true';
    button.setAttribute('aria-expanded', !buttonExpanded);
  }
});

function onChangeSelectWithOther(target) {
  const parent = target.closest('.editable-champ-drop_down_list');
  const inputGroup = parent?.querySelector('.drop_down_other');
  if (inputGroup) {
    const input = inputGroup.querySelector('input');
    if (target.value === '__other__') {
      show(inputGroup);
      input.disabled = false;
    } else {
      hide(inputGroup);
      input.disabled = true;
    }
  }
}

delegate('change', '.editable-champ-drop_down_list select', (event) => {
  onChangeSelectWithOther(event.target);
});

delegate(
  'click',
  '.editable-champ-drop_down_list input[type="radio"]',
  (event) => {
    onChangeSelectWithOther(event.target);
  }
);
