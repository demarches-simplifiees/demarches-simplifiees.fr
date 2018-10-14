import L from 'leaflet';

const LAYERS = {};

export function initMap(position) {
  const map = L.map('map', {
    scrollWheelZoom: false
  }).setView([position.lat, position.lon], position.zoom);

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);

  return map;
}

export function drawLayer(map, data, style, layerName = 'default') {
  removeLayer(map, layerName);

  if (Array.isArray(data) && data.length > 0) {
    const layer = createLayer(map, layerName);

    data.forEach(function(item) {
      layer.addData(item.geometry);
    });

    layer.setStyle(style).addTo(map);
  }
}

export function noEditStyle(style) {
  return Object.assign({}, style, {
    opacity: 0.7,
    fillOpacity: 0.5,
    color: style.fillColor
  });
}

const POLYGON_STYLE = {
  weight: 2,
  opacity: 0.3,
  color: 'white',
  dashArray: '3',
  fillOpacity: 0.7
};

export const CADASTRE_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#8a6d3b'
});

export const QP_POLYGON_STYLE = Object.assign({}, POLYGON_STYLE, {
  fillColor: '#31708f'
});

function createLayer(map, layerName) {
  const layer = (LAYERS[layerName] = new L.GeoJSON(undefined, {
    interactive: false
  }));
  layer.addTo(map);
  return layer;
}

function removeLayer(map, layerName) {
  const layer = LAYERS[layerName];

  if (layer) {
    delete LAYERS[layerName];
    map.removeLayer(layer);
  }
}
