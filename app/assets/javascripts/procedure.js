var ready;

ready = function () {
    $("#add_type_de_champs_procedure").on('click', function (e) {
        add_new_type_de_champs();

        e.stopPropagation();
        return false;
    });

    $("#add_type_de_piece_justificative_procedure").on('click', function (e) {
        add_new_type_de_piece_justificative();

        e.stopPropagation();
        return false;
    });
};

$(document).ready(ready);
$(document).on('page:load', ready);

function add_new_type_de_champs() {
    var index_id = "#type_de_champs_" + types_de_champs_index;

    $("#liste_champs").append($(index_id));
    $("#new_type_de_champs").append($(index_id).clone());
    types_de_champs_index++;

    $("#new_type_de_champs .form-inline").attr('id', 'type_de_champs_' + types_de_champs_index);

    $("#new_type_de_champs #libelle").attr('name', 'type_de_champs[' + types_de_champs_index + '][libelle]');
    $("#new_type_de_champs #libelle").val('');

    $("#new_type_de_champs #description").attr('name', 'type_de_champs[' + types_de_champs_index + '][description]');
    $("#new_type_de_champs #description").val('');

    $("#new_type_de_champs #type_champs").attr('name', 'type_de_champs[' + types_de_champs_index + '][type]');

    $("#new_type_de_champs #order_place").attr('name', 'type_de_champs[' + types_de_champs_index + '][order_place]');
    $("#new_type_de_champs #order_place").val(types_de_champs_index+1);

    $("#new_type_de_champs #id_type_de_champs").attr('name', 'type_de_champs[' + types_de_champs_index + '][id_type_de_champs]');
    $("#new_type_de_champs #id_type_de_champs").val('')

    $("#new_type_de_champs #delete").attr('name', 'type_de_champs[' + types_de_champs_index + '][delete]');
    $("#new_type_de_champs #delete").val('false')

    $("#new_type_de_champs #add_type_de_champs_button").remove();
    $("#new_type_de_champs .form-inline").append($("#add_type_de_champs_button"))
}

function add_new_type_de_piece_justificative() {
    var index_id = "#type_de_piece_justificative_" + types_de_piece_justificative_index;

    $("#liste_piece_justificative").append($(index_id));
    $("#new_type_de_piece_justificative").append($(index_id).clone());
    types_de_piece_justificative_index++;

    $("#new_type_de_piece_justificative .form-inline").attr('id', 'type_de_piece_justificative_' + types_de_piece_justificative_index);

    $("#new_type_de_piece_justificative #libelle").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][libelle]');
    $("#new_type_de_piece_justificative #libelle").val('');

    $("#new_type_de_piece_justificative #description").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][description]');
    $("#new_type_de_piece_justificative #description").val('');

    $("#new_type_de_piece_justificative #id_type_de_piece_justificative").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][id_type_de_piece_justificative]');
    $("#new_type_de_piece_justificative #id_type_de_piece_justificative").val('')

    $("#new_type_de_piece_justificative #delete").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][delete]');
    $("#new_type_de_piece_justificative #delete").val('false')

    $("#new_type_de_piece_justificative #add_type_de_piece_justificative_button").remove();
    $("#new_type_de_piece_justificative .form-inline").append($("#add_type_de_piece_justificative_button"))
}