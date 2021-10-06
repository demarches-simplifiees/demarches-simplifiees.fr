import { LngLatBounds } from 'mapbox-gl';

export function getBounds(geometry) {
  const bbox = new LngLatBounds();

  if (geometry.type === 'Point') {
    return [geometry.coordinates, geometry.coordinates];
  } else if (geometry.type === 'LineString') {
    for (const coordinate of geometry.coordinates) {
      bbox.extend(coordinate);
    }
  } else {
    for (const coordinate of geometry.coordinates[0]) {
      bbox.extend(coordinate);
    }
  }
  return bbox;
}

export function findFeature(featureCollection, value, property = 'id') {
  return featureCollection.features.find(
    (feature) => feature.properties[property] === value
  );
}

export function filterFeatureCollection(featureCollection, source) {
  return {
    type: 'FeatureCollection',
    features: featureCollection.features.filter(
      (feature) => feature.properties.source === source
    )
  };
}

export function filterFeatureCollectionByGeometryType(featureCollection, type) {
  return {
    type: 'FeatureCollection',
    features: featureCollection.features.filter(
      (feature) => feature.geometry.type === type
    )
  };
}

export function generateId() {
  return Math.random().toString(20).substr(2, 6);
}

export function getCenter(geometry, lngLat) {
  const bbox = new LngLatBounds();

  switch (geometry.type) {
    case 'Point':
      return [...geometry.coordinates];
    case 'LineString':
      return [lngLat.lng, lngLat.lat];
    default:
      for (const coordinate of geometry.coordinates[0]) {
        bbox.extend(coordinate);
      }
      return bbox.getCenter();
  }
}

export function defer() {
  const deferred = {};
  const promise = new Promise(function (resolve, reject) {
    deferred.resolve = resolve;
    deferred.reject = reject;
  });
  deferred.promise = promise;
  return deferred;
}
