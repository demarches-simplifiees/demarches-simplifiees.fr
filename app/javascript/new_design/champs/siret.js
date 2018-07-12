addEventListener('turbolinks:load', () => {
  $('[data-siret]').on('input', evt => {
    const input = $(evt.target);
    const value = input.val();
    const url = input.attr('data-siret');

    switch (value.length) {
      case 0:
        $.get(`${url}?siret=blank`);
        break;
      case 14:
        input.attr('disabled', 'disabled');
        $('.spinner').show();
        $.get(`${url}?siret=${value}`).then(
          () => {
            input.removeAttr('data-invalid');
            input.removeAttr('disabled');
            $('.spinner').hide();
          },
          () => {
            input.removeAttr('disabled');
            input.attr('data-invalid', true);
            $('.spinner').hide();
          }
        );
        break;
      default:
        if (!input.attr('data-invalid')) {
          input.attr('data-invalid', true);
          $.get(`${url}?siret=invalid`);
        }
    }
  });
});
