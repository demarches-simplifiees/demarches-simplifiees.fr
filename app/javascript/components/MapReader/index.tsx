import type { FeatureCollection } from 'geojson';

import { MapLibre } from '../shared/maplibre/MapLibre';
import { ParcelleLayer } from './components/ParcelleLayer';
import { GeoJSONLayer } from './components/GeoJSONLayer';
import { getParcellesSource } from '../shared/maplibre/utils';

const MapReader = ({
  featureCollection,
  options
}: {
  featureCollection: FeatureCollection;
  options: { layers: string[] };
}) => {
  const source = getParcellesSource(options.layers);
  return (
    <MapLibre layers={options.layers}>
      <GeoJSONLayer featureCollection={featureCollection} />
      {source ? (
        <ParcelleLayer source={source} featureCollection={featureCollection} />
      ) : null}
    </MapLibre>
  );
};

export default MapReader;
