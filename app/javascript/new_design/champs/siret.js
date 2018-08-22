import $ from 'jquery';

$(document).on('input', '[data-siret]', evt => {
  const input = $(evt.target);
  const value = input.val();
  const url = input.data('siret');

  switch (value.length) {
    case 0:
      input.removeData('invalid');
      $.get(url, { siret: 'blank' });
      break;
    case 14:
      input.attr('disabled', true);
      $('.spinner').show();
      $.get(url, { siret: value }).then(
        () => {
          input.removeData('invalid');
          input.removeAttr('disabled');
          $('.spinner').hide();
        },
        () => {
          input.removeAttr('disabled');
          input.data('invalid', true);
          $('.spinner').hide();
        }
      );
      break;
    default:
      if (!input.data('invalid')) {
        input.data('invalid', true);
        $.get(url, { siret: 'invalid' });
      }
  }
});
