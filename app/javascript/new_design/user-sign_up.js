import { on, show, hide } from '@utils';
import { suggest } from 'email-butler';

const user_new_email_selector = '#new_user > #user_email';
const suspectSuggestionsBox = document.querySelector('.suspect-email');
const emailSuggestionSpan = document.querySelector(
  '.suspect-email .question .suggested-email'
);

on(user_new_email_selector, 'blur', () => {
  // When the user leaves the email input during account creation, we check if this account looks correct.
  // If not (e.g if its "bidou@gmail.coo" or "john@yahoo.rf") we attempt to suggest a fix for the invalid email.
  const suggestion = suggest(
    document.querySelector(user_new_email_selector).value
  );
  if (suggestion.full) {
    emailSuggestionSpan.innerHTML = suggestion.full;
    show(suspectSuggestionsBox);
  }
});

export function acceptEmailSuggestion() {
  document.querySelector(user_new_email_selector).value =
    emailSuggestionSpan.innerHTML;
  hide(suspectSuggestionsBox);
}

export function discardEmailSuggestionBox() {
  hide(suspectSuggestionsBox);
}
