export default function createFeatureCollection(latLngs) {
  return {
    type: 'FeatureCollection',
    features: latLngs.map(featurePolygonLatLngs)
  };
}

function featurePolygonLatLngs(latLngs) {
  return {
    type: 'Feature',
    properties: {
      source: 'selection_utilisateur'
    },
    geometry: {
      type: 'Polygon',
      coordinates: [latLngs.map(({ lng, lat }) => [lng, lat])]
    }
  };
}
