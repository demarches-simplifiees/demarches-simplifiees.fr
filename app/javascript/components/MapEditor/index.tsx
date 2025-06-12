import { useState } from 'react';
import '@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css';
import type { FeatureCollection } from 'geojson';

import { MapLibre } from '../shared/maplibre/MapLibre';
import { useFeatureCollection } from './hooks';
import { DrawLayer } from './components/DrawLayer';
import { CadastreLayer } from './components/CadastreLayer';
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
  translations,
  ariaLabelledbyPrefix
}: {
  featureCollection: FeatureCollection;
  url: string;
  adresseSource: string;
  options: { layers: string[] };
  champId: string;
  translations: Record<string, string>;
  ariaLabelledbyPrefix?: string;
}) {
  const [cadastreEnabled, setCadastreEnabled] = useState(false);

  const { featureCollection, error, ...actions } = useFeatureCollection(
    initialFeatureCollection,
    { url }
  );

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
        ariaLabelledbyPrefix={ariaLabelledbyPrefix}
      />
      <MapLibre layers={options.layers}>
        <DrawLayer
          featureCollection={featureCollection}
          {...actions}
          enabled={!cadastreEnabled}
        />
        {options.layers.includes('cadastres') ? (
          <CadastreLayer
            featureCollection={featureCollection}
            {...actions}
            toggle={() => setCadastreEnabled((enabled) => !enabled)}
            enabled={cadastreEnabled}
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
