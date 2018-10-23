import area from '@turf/area';

export default function polygonArea(latLngs) {
  return area({
    type: 'FeatureCollection',
    features: latLngs.map(featurePolygonLatLngs)
  });
}

function featurePolygonLatLngs(latLngs) {
  return {
    type: 'Feature',
    properties: {},
    geometry: {
      type: 'Polygon',
      coordinates: [latLngs.map(({ lng, lat }) => [lng, lat])]
    }
  };
}
