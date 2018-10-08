/* globals $ */

$(document).on('turbolinks:load', init_default_data_block);

function init_default_data_block() {
  $('.default-data-block #dossier .body').toggle();
  $('.default-data-block #dossier .carret-right').toggle();
  $('.default-data-block #dossier .carret-down').toggle();

  $('.default-data-block .title').click(function() {
    toggle_default_data_bloc(this, 400);
  });

  $('.new-action').click(function() {
    var messages_block = $(this)
      .parents()
      .closest('.default-data-block')
      .find('.title');
    toggle_default_data_bloc(messages_block, 400);
  });

  $('.default-data-block.default_visible').each(function() {
    toggle_default_data_bloc($(this).find('.title'), 0);
  });

  function toggle_default_data_bloc(element, duration) {
    var block = $(element).parents('.show-block');
    if (block.attr('id') == 'messages') {
      block.children('.last-commentaire').toggle();
      $('.commentaires').animate({ scrollTop: $(this).height() }, 'slow');
    }

    block.children('.body').slideToggle(duration);

    block.find('.carret-right').toggle();
    block.find('.carret-down').toggle();
  }
}
