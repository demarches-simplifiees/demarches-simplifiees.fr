//récupération de la position de l'entreprise

function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; Openstreetmap France | &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    position = get_position();

    var map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: 13,
        layers: [OSM]
    });

    freeDraw = new L.FreeDraw({
        mode: L.FreeDraw.MODES.CREATE
    });

    map.addLayer(freeDraw);
}

function get_position() {
    var position;

    $.ajax({
        url: '/users/dossiers/' + dossier_id + '/carte/position',
        dataType: 'json',
        async: false
    }).done(function (data) {
        position = data
    });

    return position;
}

function get_ref_dossier() {
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
    if (window.location.href.indexOf('carte') > -1 && window.featureCollection.features.length == 0) {
        $("#flash_message").html('<div class="alert alert-danger">Un dessin est obligatoire.</div>');
        e.preventDefault();
        return false;
    }
}