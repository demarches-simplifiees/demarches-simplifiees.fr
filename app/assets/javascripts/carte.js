//récupération de la position de l'entreprise

function get_position(){
    var position;

    $.ajax({
        url: '/dossiers/'+dossier_id+'/carte/position',
        dataType: 'json',
        async: false
    }).done(function (data) {
        position = data
    });

    return position;
}

function get_ref_dossier (){
    $.post("http://apicarto.coremaps.com/api/v1/datastore", {
        contentType: "application/json",
        dataType: 'json',
        geom: JSON.stringify(window.featureCollection.features[0]),
        ascyn: false
    }).done(function (data) {
        $("#ref_dossier").val(data.reference);
    });
}

function submit_check_draw(e) {
    if (window.featureCollection.features.length == 0) {
        $("#flash_message").html('<div class="alert alert-danger">Un dessin est obligatoire.</div>');
        e.preventDefault();
        return false;
    }
}