import { show, hide } from '@utils';

export function showFusion() {
  show(document.querySelector('.fusion'));
  hide(document.querySelector('.new-account'));
  hide(document.querySelector('.new-account-password-confirmation'));
}

export function showNewAccount() {
  hide(document.querySelector('.fusion'));
  show(document.querySelector('.new-account'));
  hide(document.querySelector('.new-account-password-confirmation'));
}

export function showNewAccountPasswordConfirmation() {
  hide(document.querySelector('.fusion'));
  hide(document.querySelector('.new-account'));
  show(document.querySelector('.new-account-password-confirmation'));
}
