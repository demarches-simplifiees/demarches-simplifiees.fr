import { useState } from 'react';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';
import type { FeatureCollection } from 'geojson';

import { MapLibre } from '../shared/maplibre/MapLibre';
import { getParcellesSource } from '../shared/maplibre/utils';
import { useFeatureCollection } from './hooks';
import { DrawLayer } from './components/DrawLayer';
import { ParcelleLayer } from './components/ParcelleLayer';
import { AddressInput } from './components/AddressInput';
import { PointInput } from './components/PointInput';
import { ImportFileInput } from './components/ImportFileInput';
import { FlashMessage } from '../shared/FlashMessage';

export default function MapEditor({
  featureCollection: initialFeatureCollection,
  url,
  adresseSource,
  options,
  champId,
  translations
}: {
  featureCollection: FeatureCollection;
  url: string;
  adresseSource: string;
  options: { layers: string[] };
  champId: string;
  translations: Record<string, string>;
}) {
  const [parcellesEnabled, setParcellesEnabled] = useState(false);

  const { featureCollection, error, ...actions } = useFeatureCollection(
    initialFeatureCollection,
    { url }
  );

  const parcellesSource = getParcellesSource(options.layers);

  return (
    <>
      {error && <FlashMessage message={error} level="alert" fixed={true} />}

      <ImportFileInput
        featureCollection={featureCollection}
        translations={translations}
        {...actions}
      />
      <AddressInput
        source={adresseSource}
        champId={champId}
        featureCollection={featureCollection}
        translations={translations}
      />

      <MapLibre layers={options.layers}>
        <DrawLayer
          featureCollection={featureCollection}
          {...actions}
          enabled={!parcellesEnabled}
        />
        {parcellesSource ? (
          <ParcelleLayer
            source={parcellesSource}
            featureCollection={featureCollection}
            {...actions}
            toggle={() => setParcellesEnabled((enabled) => !enabled)}
            enabled={parcellesEnabled}
          />
        ) : null}
      </MapLibre>
      <PointInput
        featureCollection={featureCollection}
        translations={translations}
      />
    </>
  );
}
