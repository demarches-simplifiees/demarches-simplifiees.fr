document.addEventListener('turbolinks:load', function() {
  $('[data-siret]').on('input', function(evt) {
    var input = $(evt.target);
    var value = input.val();
    var url = input.attr('data-siret');
    switch (value.length) {
    case 0:
      $.get(url+'?siret=blank');
      break;
    case 14:
      input.attr('disabled', 'disabled');
      $('.spinner').show();
      $.get(url+'?siret='+value).then(function() {
        input.removeAttr('data-invalid');
        input.removeAttr('disabled');
        $('.spinner').hide();
      }, function() {
        input.removeAttr('disabled');
        input.attr('data-invalid', true);
        $('.spinner').hide();
      });
      break;
    default:
      if (!input.attr('data-invalid')) {
        input.attr('data-invalid', true);
        $.get(url+'?siret=invalid');
      }
    }
  });
});
