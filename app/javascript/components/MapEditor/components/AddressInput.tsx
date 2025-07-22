import { fire } from '@utils';
import type { FeatureCollection } from 'geojson';

import { RemoteComboBox } from '../../ComboBox';

export function AddressInput({
  source,
  featureCollection,
  champId,
  translations
}: {
  source: string;
  featureCollection: FeatureCollection;
  champId: string;
  translations: Record<string, string>;
}) {
  return (
    <div style={{ marginBottom: '10px' }}>
      <RemoteComboBox
        minimumInputLength={2}
        id={champId}
        loader={source}
        label={translations.address_input_label}
        description={translations.address_input_description}
        placeholder={translations.address_placeholder}
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
