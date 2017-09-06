function drawQuartiersPrioritaires (map) {
  drawLayerWithItems(map, dossierQuartiersPrioritaires, {
    fillColor: '#31708F',
    weight: 2,
    opacity: 0.7,
    color: '#31708F',
    dashArray: '3',
    fillOpacity: 0.5
  });
}
