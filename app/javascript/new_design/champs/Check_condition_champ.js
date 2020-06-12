import $ from 'jquery';

export function manage_sub_champ(event, id, id_div) {
  `${$('[id^=div_condition] *').prop('disabled', true)}`;
  `${$('#' + id_div + ' *').prop('disabled', true)}`;
  var checkbox = document.getElementById(id);
  var div_compose = document.getElementById(id_div);
  if (checkbox.checked) {
    `${$('#' + id_div + ' *').prop('disabled', false)}`;
    div_compose.style.display = 'block';
  } else {
    div_compose.style.display = 'none';
    `${$('#' + id_div + ' *').prop('disabled', true)}`;
  }
}
