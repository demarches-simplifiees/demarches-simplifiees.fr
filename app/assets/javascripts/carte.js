function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    position = get_position();

    var map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: 13,
        layers: [OSM]
    });

    var freeDraw = new L.FreeDraw({
        mode: L.FreeDraw.MODES.CREATE
    });

    map.addLayer(freeDraw);

    $.each($.parseJSON($("#json_latlngs").val()), function(i, val){
        freeDraw.createPolygon(val);
    });

    add_event_freeDraw(freeDraw);
}

function add_event_freeDraw(freeDraw){
    freeDraw.on('markers', function (e){
        $("#json_latlngs").val(JSON.stringify(e.latLngs));
    });

    $("#new").on('click', function (e){
        freeDraw.setMode(L.FreeDraw.MODES.CREATE);
    });

    $("#edit").on('click', function (e){
        freeDraw.setMode(L.FreeDraw.MODES.EDIT);
    });

    $("#delete").on('click', function (e){
        freeDraw.setMode(L.FreeDraw.MODES.DELETE);
    });
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