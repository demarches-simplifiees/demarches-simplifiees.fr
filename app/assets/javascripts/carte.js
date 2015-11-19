function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    var LON = '2.428462';
    var LAT = '46.538192';

    position = get_position() || {lon: LON, lat: LAT, zoom: 13};

    if (typeof position.zoom == 'undefined')
        position.zoom = 13;

    var map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: position.zoom,
        layers: [OSM]
    });

    var freeDraw = new L.FreeDraw({
        //mode: L.FreeDraw.MODES.CREATE
    });

    map.addLayer(freeDraw);

    if ($("#json_latlngs").val() != '' && $("#json_latlngs").val() != '[]') {
        $.each($.parseJSON($("#json_latlngs").val()), function (i, val) {
            freeDraw.createPolygon(val);
        });
        map.setView(freeDraw.polygons[0].getBounds().getCenter(), position.zoom);
    }
    else if (position.lat == LAT && position.lon == LON)
        map.setView(new L.LatLng(position.lat, position.lon), 5);

    add_event_freeDraw(freeDraw);
}

function add_event_freeDraw(freeDraw) {
    freeDraw.on('markers', function (e) {
        $("#json_latlngs").val(JSON.stringify(e.latLngs));
    });

    $("#new").on('click', function (e) {
        freeDraw.setMode(L.FreeDraw.MODES.CREATE);
    });

    $("#edit").on('click', function (e) {
        freeDraw.setMode(L.FreeDraw.MODES.EDIT);
    });

    $("#delete").on('click', function (e) {
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