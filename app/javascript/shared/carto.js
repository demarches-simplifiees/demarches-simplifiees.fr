const LON = '2.428462';
const LAT = '46.538192';
const DEFAULT_POSITION = { lon: LON, lat: LAT, zoom: 5 };
import L from 'leaflet';

export { DEFAULT_POSITION, LAT, LON };
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
