import { gpx, kml } from '@tmcw/togeojson/dist/togeojson.es.js';
import { generateId } from '../shared/mapbox/utils';

export function readGeoFile(file) {
  const isGpxFile = file.name.includes('.gpx');
  const reader = new FileReader();

  return new Promise((resolve) => {
    reader.onload = (event) => {
      const xml = new DOMParser().parseFromString(
        event.target.result,
        'text/xml'
      );
      const featureCollection = normalizeFeatureCollection(
        isGpxFile ? gpx(xml) : kml(xml),
        file.name
      );

      resolve(featureCollection);
    };
    reader.readAsText(file, 'UTF-8');
  });
}

function normalizeFeatureCollection(featureCollection, filename) {
  const features = [];
  for (const feature of featureCollection.features) {
    switch (feature.geometry.type) {
      case 'MultiPoint':
        for (const coordinates of feature.geometry.coordinates) {
          features.push({
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates
            },
            properties: feature.properties
          });
        }
        break;
      case 'MultiLineString':
        for (const coordinates of feature.geometry.coordinates) {
          features.push({
            type: 'Feature',
            geometry: {
              type: 'LineString',
              coordinates
            },
            properties: feature.properties
          });
        }
        break;
      case 'MultiPolygon':
        for (const coordinates of feature.geometry.coordinates) {
          features.push({
            type: 'Feature',
            geometry: {
              type: 'Polygon',
              coordinates
            },
            properties: feature.properties
          });
        }
        break;
      case 'GeometryCollection':
        for (const geometry of feature.geometry.geometries) {
          features.push({
            type: 'Feature',
            geometry,
            properties: feature.properties
          });
        }
        break;
      default:
        features.push(feature);
    }
  }

  featureCollection.filename = `${generateId()}-${filename}`;
  featureCollection.features = features.map((feature) => ({
    ...feature,
    properties: {
      ...feature.properties,
      filename: featureCollection.filename
    }
  }));
  return featureCollection;
}
