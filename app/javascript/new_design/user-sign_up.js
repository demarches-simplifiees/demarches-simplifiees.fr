import { on, show, hide } from '@utils';

const USER_NEW_EMAIL_SELECTOR = '#new_user > #user_email';
const suspectSuggestionsBox = document.querySelector('.suspect-email');
const emailSuggestionSpan = document.querySelector(".suspect-email .question .suggested-email");

on(USER_NEW_EMAIL_SELECTOR, 'blur', _ => {
  emailSuggestionSpan.innerHTML = 'bidou@plop.com';
  show(suspectSuggestionsBox)
});

export function acceptEmailSuggestion() {
  document.querySelector(USER_NEW_EMAIL_SELECTOR).value = emailSuggestionSpan.innerHTML;
  hide(suspectSuggestionsBox);
}

export function discardEmailSuggestionBox() {
  hide(suspectSuggestionsBox);
}

