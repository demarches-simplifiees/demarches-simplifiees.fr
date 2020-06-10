import { LngLatBounds } from 'mapbox-gl';
import { useEffect } from 'react';

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

export function fitBounds(map, feature) {
  if (map) {
    map.fitBounds(getBounds(feature.geometry), { padding: 100 });
  }
}

export function findFeature(featureCollection, id) {
  return featureCollection.features.find(
    (feature) => feature.properties.id === id
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

export function noop() {}

export function generateId() {
  return Math.random().toString(20).substr(2, 6);
}

export function useEvent(eventName, callback) {
  return useEffect(() => {
    addEventListener(eventName, callback);
    return () => removeEventListener(eventName, callback);
  }, [eventName, callback]);
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
