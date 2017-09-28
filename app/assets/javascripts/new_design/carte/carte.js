function initCarto() {
  if ($("#map").length > 0) {
    var position = getPosition() || defaultGestionnairePosition();

    var map = L.map('map', {
      scrollWheelZoom: false
    }).setView([position.lat, position.lon], position.zoom);

    L.tileLayer('http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    // draw external polygons
    drawCadastre(map);
    drawQuartiersPrioritaires(map);

    // draw user polygon
    drawUserSelection(map);
  }
}

$(document).on('turbolinks:load', initCarto);

function drawUserSelection(map) {
  if (dossierJsonLatLngs.length > 0) {
    var polygon = L.polygon(dossierJsonLatLngs, { color: 'red', zIndex: 3 }).addTo(map);
    map.fitBounds(polygon.getBounds());
  }
}

function defaultGestionnairePosition() {
  var LON = '2.428462';
  var LAT = '46.538192';
  return { lon: LON, lat: LAT, zoom: 5 }
}

function getPosition() {
  var position;

  $.ajax({
    url: getPositionUrl,
    dataType: 'json',
    async: false
  }).done(function (data) {
    position = data
  });

  return position;
}

function drawLayerWithItems(map, items, style) {
  if (Array.isArray(items) && items.length > 0) {
    var layer = new L.GeoJSON();

    items.forEach(function (item) {
      layer.addData(item.geometry);
    });

    layer.setStyle(style).addTo(map);
  }
}
