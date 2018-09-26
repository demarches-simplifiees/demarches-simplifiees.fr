import $ from 'jquery';

export function displayPasswordStrength(strengthBarId, score) {
  var $bar = $('#' + strengthBarId),
    passwordMessage;

  $bar.removeClass('strength-1 strength-2 strength-3 strength-4');

  if (score < 4) {
    passwordMessage = 'Mot de passe pas assez complexe';
  } else {
    passwordMessage = 'Mot de passe suffisamment complexe';
  }

  $bar.text(passwordMessage);
  $bar.addClass('strength-' + score);
}

export function checkPasswordStrength(event, strengthBarId) {
  var $target = $(event.target),
    password = $target.val();

  if (password.length > 2) {
    $.post(
      '/admin/activate/test_password_strength',
      { password: password },
      function(data) {
        displayPasswordStrength(strengthBarId, data.score);
      }
    );
  } else {
    displayPasswordStrength(strengthBarId, 0);
  }
}
