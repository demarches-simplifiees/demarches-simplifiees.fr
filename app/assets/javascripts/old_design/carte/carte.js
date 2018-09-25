var LON = '2.428462';
var LAT = '46.538192';

function initCarto() {
  OSM = L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  });

  position = get_position() || default_gestionnaire_position();

  map = L.map("map", {
    center: new L.LatLng(position.lat, position.lon),
    zoom: position.zoom,
    layers: [OSM],
    scrollWheelZoom: false
  });

  icon = L.icon({
    iconUrl: '/assets/marker-icon.png',
    //shadowUrl: 'leaf-shadow.png',

    iconSize: [34.48, 40], // size of the icon
    //shadowSize:   [50, 64], // size of the shadow
    iconAnchor: [20, 20] // point of the icon which will correspond to marker's location
    //shadowAnchor: [4, 62],  // the same for the shadow
    //popupAnchor:  [-3, -76] // point from which the popup should open relative to the iconAnchor
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
  add_event_search_address();
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

    add_event_edit();

    get_external_data(e.latLngs);
  });

  $("#map").on('click', function(){
    freeDraw.setMode(L.FreeDraw.MODES.VIEW);
  });

  $("#new").on('click', function (e) {
    freeDraw.setMode(L.FreeDraw.MODES.CREATE);
  });

  $("#delete").on('click', function (e) {
    freeDraw.setMode(L.FreeDraw.MODES.DELETE);
  });
}

function add_event_edit (){
  $(".leaflet-container g path").on('click', function (e) {
    setTimeout(function(){freeDraw.setMode(L.FreeDraw.MODES.EDIT | L.FreeDraw.MODES.DELETE)}, 50);
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

function get_address_point(request) {
  $.get('/ban/address_point', { request: request })
    .done(function (data) {
      if (data.lat !== null) {
        map.setView(new L.LatLng(data.lat, data.lon), data.zoom);
      }
    });
}

function jsObject_to_array(qp_list) {
  return Object.keys(qp_list).map(function (v) {
    return qp_list[v];
  });
}

function add_event_search_address() {
  $("#search-by-address input[type='address']").bind('autocomplete:select', function (ev, suggestion) {
    get_address_point(suggestion['label']);
  });

  $("#search-by-address input[type='address']").keypress(function (e) {
    if (e.keyCode == 13)
      get_address_point($(this).val());
  });
}
