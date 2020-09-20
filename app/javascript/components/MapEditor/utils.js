import { gpx, kml } from '@tmcw/togeojson/dist/togeojson.es.js';

export const polygonCadastresFill = {
  'fill-color': '#EC3323',
  'fill-opacity': 0.3
};

export const polygonCadastresLine = {
  'line-color': 'rgba(255, 0, 0, 1)',
  'line-width': 4,
  'line-dasharray': [1, 1]
};

export function normalizeFeatureCollection(featureCollection) {
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

  featureCollection.features = features;
  return featureCollection;
}

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
        isGpxFile ? gpx(xml) : kml(xml)
      );

      resolve(featureCollection);
    };
    reader.readAsText(file, 'UTF-8');
  });
}
