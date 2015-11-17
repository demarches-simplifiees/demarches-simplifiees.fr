
var ready = function () {
    $("#liste_champ").on("ajax:success", "div", function(event, data, status, xhr) {
      $(event.target).parents('.form-inline').fadeOut("slow", function() {
        return $(this).remove();
      });
    });
};

$(document).ready(ready);
$(document).on('page:load', ready);



