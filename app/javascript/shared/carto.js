const LON = '2.428462';
const LAT = '46.538192';
const DEFAULT_POSITION = { lon: LON, lat: LAT, zoom: 5 };
import L from 'leaflet';

export { DEFAULT_POSITION, LAT, LON };
const LAYERS = {};

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
