import 'maplibre-gl/dist/maplibre-gl.css';
import type { FeatureCollection } from 'geojson';

import { MapLibre } from '../shared/maplibre/MapLibre';
import { CadastreLayer } from './components/CadastreLayer';
import { GeoJSONLayer } from './components/GeoJSONLayer';

const MapReader = ({
  featureCollection,
  options
}: {
  featureCollection: FeatureCollection;
  options: { layers: string[] };
}) => {
  return (
    <MapLibre layers={options.layers}>
      <GeoJSONLayer featureCollection={featureCollection} />
      <CadastreLayer featureCollection={featureCollection} />
    </MapLibre>
  );
};

export default MapReader;
