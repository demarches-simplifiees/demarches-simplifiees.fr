$(document).on('page:load', init_path_modal);
$(document).ready(init_path_modal);

function init_path_modal() {
    path_modal_action();
    path_validation_action();
    path_type_init();
    path_validation($("input[id='procedure_path']"));
}

function path_modal_action() {
    $('#publishModal').on('show.bs.modal', function (event) {
        $("#publishModal .modal-body .table .tr_content").hide();

        var button = $(event.relatedTarget) // Button that triggered the modal
        var modal_title = button.data('modal_title'); // Extract info from data-* attributes
        var modal_index = button.data('modal_index'); // Extract info from data-* attributes

        var modal = $(this)
        modal.find('#publishModal_title').html(modal_title);
        $("#publishModal .modal-body .table #"+modal_index).show();
    })
}


function path_validation_action() {
    $("input[id='procedure_path']").keyup(function (key) {
        if (key.keyCode != 13)
            path_validation(this);
    });
}

function togglePathMessage(valid, mine) {
    $('#path_messages .message').hide();

    if (valid === true && mine === true) {
        $('#path_is_mine').show();
    } else if (valid === true && mine === false) {
        $('#path_is_not_mine').show();
    } else if (valid === false && mine === null) {
        $('#path_is_invalid').show();
    }

    if ((valid && mine === null) || mine === true)
        $('#publishModal #publish').removeAttr('disabled')
    else
        $('#publishModal #publish').attr('disabled', 'disabled')
}

function path_validation(el) {
    var valid = validatePath($(el).val());
    toggleErrorClass(el, valid);
    togglePathMessage(valid, null);
}

function validatePath(path) {
    console.log(path);

    var re = /^[a-z0-9_]{3,30}$/;
    return re.test(path);
}


function path_type_init() {
    display = 'label';

    var bloodhound = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace(display),
        queryTokenizer: Bloodhound.tokenizers.whitespace,

        remote: {
            url: '/admin/procedures/path_list?request=%QUERY',
            wildcard: '%QUERY'
        }
    });
    bloodhound.initialize();

    $("#procedure_path").typeahead({
        minLength: 1
    }, {
        display: display,
        source: bloodhound,
        templates: {
            suggestion: Handlebars.compile("<div class='path_mine_{{mine}}'>{{label}}</div>")
        },
        limit: 5
    });

    $('#procedure_path').bind('typeahead:select', function(ev, suggestion) {
        togglePathMessage(true, suggestion['mine']);
    });
}