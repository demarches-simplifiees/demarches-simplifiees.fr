import { delegate, show, hide } from '@utils';
import { suggest } from 'email-butler';

const userNewEmailSelector = '#new_user input#user_email';
const passwordFieldSelector = '#new_user input#user_password';
const suggestionsSelector = '.suspect-email';
const emailSuggestionSelector = '.suspect-email .email-suggestion-address';

delegate('focusout', userNewEmailSelector, () => {
  // When the user leaves the email input during account creation, we check if this account looks correct.
  // If not (e.g if its "bidou@gmail.coo" or "john@yahoo.rf"), we attempt to suggest a fix for the invalid email.
  const userEmailInput = document.querySelector(userNewEmailSelector);
  const suggestedEmailSpan = document.querySelector(emailSuggestionSelector);
  const email = userEmailInput.value;

  if (email.toLowerCase().endsWith('@gmail.pf')) {
    const address = email.substring(0, email.indexOf('@'));
    suggestedEmailSpan.innerHTML = address + '@gmail.com';
    show(document.querySelector(suggestionsSelector));
  } else if (email.toLowerCase().endsWith('@mail.pf')) {
    hide(document.querySelector(suggestionsSelector));
  } else {
    const suggestion = suggest(email);
    if (suggestion && suggestion.full && suggestedEmailSpan) {
      suggestedEmailSpan.innerHTML = suggestion.full;
      show(document.querySelector(suggestionsSelector));
    } else {
      hide(document.querySelector(suggestionsSelector));
    }
  }
});

export function acceptEmailSuggestion() {
  const userEmailInput = document.querySelector(userNewEmailSelector);
  const suggestedEmailSpan = document.querySelector(emailSuggestionSelector);

  userEmailInput.value = suggestedEmailSpan.innerHTML;
  hide(document.querySelector(suggestionsSelector));
  document.querySelector(passwordFieldSelector).focus();
}

export function discardEmailSuggestionBox() {
  hide(document.querySelector(suggestionsSelector));
}
