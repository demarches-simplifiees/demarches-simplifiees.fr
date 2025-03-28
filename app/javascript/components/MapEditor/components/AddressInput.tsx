import { fire } from '@utils';
import type { FeatureCollection } from 'geojson';

import { RemoteComboBox } from '../../ComboBox';

export function AddressInput({
  source,
  featureCollection,
  champId
}: {
  source: string;
  featureCollection: FeatureCollection;
  champId: string;
}) {
  return (
    <div style={{ marginBottom: '10px' }}>
      <RemoteComboBox
        minimumInputLength={2}
        id={champId}
        loader={source}
        label="Rechercher une Adresse"
        description="Saisissez au moins 2 caractères"
        onChange={(item) => {
          if (item && item.data) {
            fire(document, 'map:zoom', {
              featureCollection,
              feature: item.data
            });
          }
        }}
      />
    </div>
  );
}
