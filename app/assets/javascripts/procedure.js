var ready = function () {
    $("#add_type_de_champs_procedure").on('click', function (e) {
        add_new_type_de('champs');

        return stop_event(e);
    });

    $("#add_type_de_piece_justificative_procedure").on('click', function (e) {
        add_new_type_de('piece_justificative');

        return stop_event(e);
    });

    add_delete_type_de_champs_listener_on_click("#liste_champs .btn-danger");
    add_delete_type_de_champs_listener_on_click("#new_type_de_champs .btn-danger");

    add_delete_type_de_piece_justificative_listener_on_click("#liste_piece_justificative .btn-danger");
    add_delete_type_de_piece_justificative_listener_on_click("#new_type_de_piece_justificative .btn-danger");
};

$(document).ready(ready);
$(document).on('page:load', ready);

function stop_event(e) {
    e.stopPropagation();
    e.preventDefault();
    return false;
}

function add_delete_type_de_champs_listener_on_click(node_id) {
    $(node_id).on('click', function (e) {
        var index_type_de_champs = (e.target.id).replace('delete_type_de_champs_', '').replace('_procedure', '')

        delete_type_de_champs(index_type_de_champs);

        return stop_event(e);
    });
}

function add_delete_type_de_piece_justificative_listener_on_click(node_id) {
    $(node_id).on('click', function (e) {
        var index_type_de_piece_justificative = (e.target.id).replace('delete_type_de_piece_justificative_', '').replace('_procedure', '')

        delete_type_de_piece_justificative(index_type_de_piece_justificative);

        return stop_event(e);
    });
}


function add_new_type_de(type_libelle) {
    var CHAMPS = 0, PJ = 1, ERROR = -1;

    if (is_champs_or_pj() == ERROR) return false;

    function is_champs_or_pj() {
        if (type_libelle == 'champs') return CHAMPS;
        else if (type_libelle == 'piece_justificative') return PJ;
        else return ERROR;
    }

    function which_index() {
        return (is_champs_or_pj() == CHAMPS ? types_de_champs_index : types_de_piece_justificative_index)
    }

    $("#liste_" + type_libelle).append($("#type_de_" + type_libelle + "_" + which_index()));
    $("#new_type_de_" + type_libelle).append($("#type_de_" + type_libelle + "_" + which_index()).clone());

    $("#delete_type_de_" + type_libelle + "_" + which_index() + "_button").show();

    if (is_champs_or_pj() == CHAMPS) {
        types_de_champs_index++;
        add_new_type_de_champs_params(which_index());
    }
    else if (is_champs_or_pj() == PJ) {
        types_de_piece_justificative_index++;
        add_new_type_de_piece_justificative_params(which_index());
    }

    $("#new_type_de_" + type_libelle + " .form-inline").attr('id', 'type_de_' + type_libelle + '_' + which_index());

    $("#new_type_de_" + type_libelle + " #id_type_de_" + type_libelle + "").attr('name', 'type_de_' + type_libelle + '[' + which_index() + '][id_type_de_' + type_libelle + ']');
    $("#new_type_de_" + type_libelle + " #id_type_de_" + type_libelle + "").val('');

    $("#new_type_de_" + type_libelle + " #delete").attr('name', 'type_de_' + type_libelle + '[' + which_index() + '][delete]');
    $("#new_type_de_" + type_libelle + " #delete").val('false');

    $("#new_type_de_" + type_libelle + " #delete_type_de_" + type_libelle + "_" + (which_index() - 1) + "_button").attr('id', "delete_type_de_" + type_libelle + "_" + which_index() + "_button");
    $("#new_type_de_" + type_libelle + " #delete_type_de_" + type_libelle + "_" + (which_index() - 1) + "_procedure").attr('id', "delete_type_de_" + type_libelle + "_" + which_index() + "_procedure");

    if (is_champs_or_pj() == CHAMPS)
        add_delete_type_de_champs_listener_on_click("#delete_type_de_champs_" + which_index() + "_procedure");
    else if (is_champs_or_pj() == PJ)
        add_delete_type_de_piece_justificative_listener_on_click("#delete_type_de_piece_justificative_" + which_index() + "_procedure");

    $("#new_type_de_" + type_libelle + " #add_type_de_" + type_libelle + "_button").remove();
    $("#new_type_de_" + type_libelle + " .form-inline").append($("#add_type_de_" + type_libelle + "_button"))
}

function add_new_type_de_champs_params() {
    $("#new_type_de_champs #libelle").attr('name', 'type_de_champs[' + types_de_champs_index + '][libelle]');
    $("#new_type_de_champs #libelle").val('');

    $("#new_type_de_champs #description").attr('name', 'type_de_champs[' + types_de_champs_index + '][description]');
    $("#new_type_de_champs #description").val('');

    $("#new_type_de_champs #type_champs").attr('name', 'type_de_champs[' + types_de_champs_index + '][type]');

    $("#new_type_de_champs #order_place").attr('name', 'type_de_champs[' + types_de_champs_index + '][order_place]');
    $("#new_type_de_champs #order_place").val(types_de_champs_index + 1);
}

function add_new_type_de_piece_justificative_params() {
    $("#new_type_de_piece_justificative #libelle").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][libelle]');
    $("#new_type_de_piece_justificative #libelle").val('');

    $("#new_type_de_piece_justificative #description").attr('name', 'type_de_piece_justificative[' + types_de_piece_justificative_index + '][description]');
    $("#new_type_de_piece_justificative #description").val('');
}


function delete_type_de_champs(index) {
    $("#type_de_champs_" + index).hide();
    $("#type_de_champs_" + index + " #delete").val('true');
}

function delete_type_de_piece_justificative(index) {
    $("#type_de_piece_justificative_" + index).hide();
    $("#type_de_piece_justificative_" + index + " #delete").val('true');
}