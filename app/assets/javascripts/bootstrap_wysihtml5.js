$(document).ready(wysihtml5_active);
$(document).on('page:load', wysihtml5_active);

function wysihtml5_active (){
    $('.wysihtml5').each(function(i, elem) {
        $(elem).wysihtml5({ toolbar:{ "fa": true } });
    });
}