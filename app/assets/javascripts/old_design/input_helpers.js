/* globals $ */

$(document).on('turbolinks:load', action_type_de_champs);

function action_type_de_champs() {
  $("input[type='email']").on('change', function() {
    toggleErrorClass(this, validateEmail($(this).val()));
  });

  $("input[type='number']").on('change', function() {
    toggleErrorClass(this, validateNumber($(this).val()));
  });

  $("input[type='phone']").on('change', function() {
    var val = $(this).val();
    val = val.replace(/[ ]/g, '');

    toggleErrorClass(this, validatePhone(val));
  });
}

function toggleErrorClass(node, boolean) {
  if (boolean) $(node).removeClass('input-error');
  else $(node).addClass('input-error');
}

function validatePhone(phone) {
  var re = /^(0|(\+[1-9]{2})|(00[1-9]{2}))[1-9][0-9]{8}$/;
  return validateInput(phone, re);
}

function validateEmail(email) {
  var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  return validateInput(email, re);
}

function validateNumber(number) {
  var re = /^[0-9]+$/;
  return validateInput(number, re);
}

function validateInput(input, regex) {
  return regex.test(input);
}
