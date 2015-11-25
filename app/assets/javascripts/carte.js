function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    var LON = '2.428462';
    var LAT = '46.538192';

    position = get_position() || {lon: LON, lat: LAT, zoom: 13};

    if (typeof position.zoom == 'undefined')
        position.zoom = 13;

    map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: position.zoom,
        layers: [OSM]
    });

    display_qp([]);

    freeDraw = new L.FreeDraw({
        //mode: L.FreeDraw.MODES.CREATE
    });

    map.addLayer(freeDraw);

    if ($("#json_latlngs").val() != '' && $("#json_latlngs").val() != '[]') {
        $.each($.parseJSON($("#json_latlngs").val()), function (i, val) {
            freeDraw.createPolygon(val);
        });

        map.fitBounds(freeDraw.polygons[0].getBounds());
    }
    else if (position.lat == LAT && position.lon == LON)
        map.setView(new L.LatLng(position.lat, position.lon), 5);

    add_event_freeDraw();
}

function add_event_freeDraw() {
    freeDraw.on('markers', function (e) {
        $("#json_latlngs").val(JSON.stringify(e.latLngs));
        display_qp(get_qp(e.latLngs)['quartier_prioritaires']);
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

function get_qp(coordinates) {
    var qp;

    $.ajax({
        method: 'post',
        url: '/users/dossiers/' + dossier_id + '/carte/qp',
        data: {coordinates: JSON.stringify(coordinates)},
        dataType: 'json',
        async: false
    }).done(function (data) {
        qp = data
    });

    return qp;
}

function display_qp(qp_list) {
    qp_array = jsObject_to_array(qp_list);

    $("#qp_list ul").html('');

    new_qpLayer();

    if (qp_array.length > 0) {
        qp_array.forEach(function (qp) {
            $("#qp_list ul").append('<li>' + qp.commune + ' : ' + qp.nom + '</li>');
            qpItems.addData(qp.geometry)
        });
    }
    else
        $("#qp_list ul").html('<li>AUCUN</li>');
}

function new_qpLayer() {
    if (typeof qpItems != 'undefined')
        map.removeLayer(qpItems);

    qpItems = new L.GeoJSON();
    qpItems.addTo(map);
}

function jsObject_to_array(qp_list) {
    return Object.keys(qp_list).map(function (v) {
        return qp_list[v];
    });
}
