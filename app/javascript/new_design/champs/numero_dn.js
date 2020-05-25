import { delegate } from '@utils';

addEventListener('DOMContentLoaded', dn_init);

function selector(base) {
  return 'input[data-' + base + ']';
}

function setParams(input, side_ref, variable) {
  let side_input = input.parentElement.querySelector(selector(side_ref));
  let value = variable + '=' + input.value;
  side_input.setAttribute('data-params', value);
}

function handleDN(event) {
  setParams(event.target, 'ddn', 'dn');
}

function handleDDN(event) {
  setParams(event.target, 'dn', 'ddn');
}

function dn_init() {
  for (let input of document.querySelectorAll(selector('dn'))) {
    setParams(input, 'ddn', 'dn');
  }
  for (let input of document.querySelectorAll(selector('ddn'))) {
    setParams(input, 'dn', 'ddn');
  }
  delegate('input', selector('dn'), handleDN);
  delegate('input', selector('ddn'), handleDDN);
}
