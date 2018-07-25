import L from 'leaflet';

function drawLayerWithItems(map, items, style) {
  if (Array.isArray(items) && items.length > 0) {
    const layer = new L.GeoJSON();

    items.forEach(function(item) {
      layer.addData(item.geometry);
    });

    layer.setStyle(style).addTo(map);
  }
}

export function drawCadastre(map, { dossierCadastres }) {
  drawLayerWithItems(map, dossierCadastres, {
    fillColor: '#8A6D3B',
    weight: 2,
    opacity: 0.7,
    color: '#8A6D3B',
    dashArray: '3',
    fillOpacity: 0.5
  });
}

export function drawQuartiersPrioritaires(
  map,
  { dossierQuartiersPrioritaires }
) {
  drawLayerWithItems(map, dossierQuartiersPrioritaires, {
    fillColor: '#31708F',
    weight: 2,
    opacity: 0.7,
    color: '#31708F',
    dashArray: '3',
    fillOpacity: 0.5
  });
}

export function drawUserSelection(map, { dossierJsonLatLngs }) {
  if (dossierJsonLatLngs.length > 0) {
    const polygon = L.polygon(dossierJsonLatLngs, {
      color: 'red',
      zIndex: 3
    }).addTo(map);
    map.fitBounds(polygon.getBounds());
  }
}
