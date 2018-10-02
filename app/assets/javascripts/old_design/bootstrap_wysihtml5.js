/* globals $ */

$(document).on('turbolinks:load', wysihtml5_active);

function wysihtml5_active() {
  $('.wysihtml5').each(function(i, elem) {
    $(elem).wysihtml5({
      toolbar: {
        fa: true,
        link: false,
        color: false
      },
      parserRules: {
        tags: {
          p: {},
          h1: {},
          h2: {},
          h3: {},
          h4: {},
          h5: {},
          h6: {},
          b: {},
          i: {},
          u: {},
          small: {},
          blockquote: {},
          ul: {},
          ol: {},
          li: {},
          img: {},
          code: {
            unwrap: 1
          }
        }
      },
      locale: 'fr-FR'
    });
  });
}
