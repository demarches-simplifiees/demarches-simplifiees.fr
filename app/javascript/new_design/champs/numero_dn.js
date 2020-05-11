import { delegate } from '@utils';

const dnSelector = `input[data-dn]`;
const ddnSelector = `input[data-ddn]`;

function handleDN(event) {
  let ddn = event.target.parentElement.querySelector('input[data-ddn]');
  ddn.setAttribute('data-params', 'dn=' + event.target.value);
}

function handleDDN(event) {
  let dn = event.target.parentElement.querySelector('input[data-dn]');
  dn.setAttribute('data-params', 'ddn=' + event.target.value);
}

delegate('input', dnSelector, handleDN);
delegate('input', ddnSelector, handleDDN);
