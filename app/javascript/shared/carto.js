const LON = '2.428462';
const LAT = '46.538192';
const DEFAULT_POSITION = { lon: LON, lat: LAT, zoom: 5 };
import L from 'leaflet';

export { DEFAULT_POSITION, LAT, LON };
const LAYERS = {};

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
