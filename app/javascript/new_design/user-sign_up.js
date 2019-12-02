import { delegate, show, hide } from '@utils';
import { suggest } from 'email-butler';

const userNewEmailSelector = '#new_user input#user_email';
const suggestionsSelector = '.suspect-email';
const emailSuggestionSelector = '.suspect-email .suggested-email';

delegate('focusout', userNewEmailSelector, () => {
  // When the user leaves the email input during account creation, we check if this account looks correct.
  // If not (e.g if its "bidou@gmail.coo" or "john@yahoo.rf"), we attempt to suggest a fix for the invalid email.
  const userEmailInput = document.querySelector(userNewEmailSelector);
  const suggestedEmailSpan = document.querySelector(emailSuggestionSelector);

  const suggestion = suggest(userEmailInput.value);
  if (suggestion && suggestion.full) {
    suggestedEmailSpan.innerHTML = suggestion.full;
    show(document.querySelector(suggestionsSelector));
  }
});

export function acceptEmailSuggestion() {
  const userEmailInput = document.querySelector(userNewEmailSelector);
  const suggestedEmailSpan = document.querySelector(emailSuggestionSelector);

  userEmailInput.value = suggestedEmailSpan.innerHTML;
  hide(document.querySelector(suggestionsSelector));
}

export function discardEmailSuggestionBox() {
  hide(document.querySelector(suggestionsSelector));
}
