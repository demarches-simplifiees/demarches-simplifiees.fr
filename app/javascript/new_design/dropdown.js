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

const radios = document.querySelectorAll('input[type="radio"]');
const selects = Array.from(
  document.querySelectorAll('.select_drop_down_other')
);
const radioInputs = Array.from(
  document.querySelectorAll('.text_field_drop_down_other_radio')
);

const radioNotices = Array.from(
  document.querySelectorAll('.drop_down_other_radio_notice')
);

const selectNotices = Array.from(
  document.querySelectorAll('.drop_down_other_select_notice')
);

const selectInputs = Array.from(
  document.querySelectorAll('.text_field_drop_down_other_select')
);

const radioButtons = Array.from(
  document.querySelectorAll('.radio_button_drop_down_other')
);

const radioButtonsObject = radioButtons.map((radioButton, index) => {
  return {
    radioButton: radioButton,
    input: radioInputs[index],
    notice: radioNotices[index],
    key: radioButton.getAttribute('name')
  };
});

const selectObject = selects.map((select, index) => {
  return {
    select: select,
    input: selectInputs[index],
    notice: selectNotices[index],
    key: select.getAttribute('name')
  };
});

for (const el of selectObject) {
  selects.forEach((select) => {
    select.addEventListener('change', () => {
      if (el.select.value === 'Autre') {
        el.notice.style.display = 'block';
        el.input.setAttribute('name', el.key);
      } else {
        el.notice.style.display = 'none';
        el.input.setAttribute('name', '');
      }
    });
  });
}

for (const el of radioButtonsObject) {
  radios.forEach((radio) => {
    radio.addEventListener('click', () => {
      if (el.radioButton.checked) {
        el.notice.style.display = 'block';
        el.input.setAttribute('name', el.key);
      } else {
        el.notice.style.display = 'none';
        el.input.setAttribute('name', '');
      }
    });
  });
}
