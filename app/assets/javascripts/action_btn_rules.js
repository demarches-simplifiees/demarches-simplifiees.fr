$(document).on('page:load', init_action_btn_rules);
$(document).ready(init_action_btn_rules);

function init_action_btn_rules() {
  $('.btn-send').click(function () {
    $(this).addClass("disabled");
    this.addEventListener("click", lock_btn);
  });

  function lock_btn(event) {
    event.preventDefault();
  }
}
