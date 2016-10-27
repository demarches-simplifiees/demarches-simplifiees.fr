$(document).on('page:load', action_type_de_champs);
$(document).ready(action_type_de_champs);


function action_type_de_champs() {
    $("input[type='email']").on('change', function () {
        toggleErrorClass(this, validateEmail($(this).val()));
    });

    $("input[type='phone']").on('change', function () {
        val = $(this).val();
        val = val.replace(/[ ]/g, '');

        toggleErrorClass(this, validatePhone(val));
    });

    $("#liste_champs input").on('focus', function () {
        $("#description_" + this.id).slideDown();
    });

    $("#liste_champs input").on('blur', function () {
        $("#description_" + this.id).slideUp();
    });

    address_type_init();
    toggle_header_section_composents();
}

function toggleErrorClass(node, boolean) {
    if (boolean)
        $(node).removeClass('input-error');
    else
        $(node).addClass('input-error');
}

function validatePhone(phone) {
    var re = /^(0|(\+[1-9]{2})|(00[1-9]{2}))[1-9][0-9]{8}$/;
    return validateInput(phone, re)
}

function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return validateInput(email, re)
}

function validateInput(input, regex) {
    return regex.test(input);
}

function toggle_header_section_composents() {
    $("a.mask_section_button").on('click', function (e) {
        target = e.currentTarget;

        header_section_id = target.id.split('mask_button_')[1];
        header_section_composents = $(".header_section_" + header_section_id);

        header_section_composents.slideToggle(200, function () {
            if (header_section_composents.css('display') == 'none') {
                $(target).html('Afficher la section <i class="fa fa-chevron-down" />')
            }
            else {
                $(target).html('Masquer la section <i class="fa fa-chevron-up" />')
            }
        });
    });
}