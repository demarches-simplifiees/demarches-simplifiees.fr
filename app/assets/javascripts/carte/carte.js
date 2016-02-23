var LON = '2.428462';
var LAT = '46.538192';

function initCarto() {
    OSM = L.tileLayer("http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    });

    position = get_position() || default_gestionnaire_position();

    map = L.map("map", {
        center: new L.LatLng(position.lat, position.lon),
        zoom: position.zoom,
        layers: [OSM]
    });

    if (qp_active())
        display_qp(JSON.parse($("#quartier_prioritaires").val()));

    if (cadastre_active())
        display_cadastre(JSON.parse($("#cadastres").val()));

    freeDraw = new L.FreeDraw();
    freeDraw.options.setSmoothFactor(4);
    freeDraw.options.simplifyPolygon = false;

    map.addLayer(freeDraw);

    if ($("#json_latlngs").val() != '' && $("#json_latlngs").val() != '[]') {
        map.setZoom(18);

        $.each($.parseJSON($("#json_latlngs").val()), function (i, val) {
            freeDraw.createPolygon(val);
        });

        map.fitBounds(freeDraw.polygons[0].getBounds());
    }
    else if (position.lat == LAT && position.lon == LON)
        map.setView(new L.LatLng(position.lat, position.lon), position.zoom);

    add_event_freeDraw();
}

function default_gestionnaire_position() {
    return {lon: LON, lat: LAT, zoom: 5}
}

function get_external_data(latLngs) {
    if (qp_active())
        display_qp(get_qp(latLngs));

    if (cadastre_active()) {
        polygons = {"type": "FeatureCollection", "features": []};

        for (i = 0; i < latLngs.length; i++)
            polygons.features.push(feature_polygon_latLngs(latLngs[i]))

        cadastre_list = [{zoom_error: true}];

        if (turf_area(polygons) < 300000)
            cadastre_list = get_cadastre(latLngs);

        display_cadastre(cadastre_list);
    }
}

function feature_polygon_latLngs(coordinates) {
    return ({
        "type": "Feature",
        "properties": {},
        "geometry": {
            "type": "Polygon",
            "coordinates": [
                JSON.parse(L.FreeDraw.Utilities.getJsonPolygons([coordinates]))['latLngs']
            ]
        }
    })
}

function add_event_freeDraw() {
    freeDraw.on('markers', function (e) {
        $("#json_latlngs").val(JSON.stringify(e.latLngs));

        get_external_data(e.latLngs);
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

function jsObject_to_array(qp_list) {
    return Object.keys(qp_list).map(function (v) {
        return qp_list[v];
    });
}
