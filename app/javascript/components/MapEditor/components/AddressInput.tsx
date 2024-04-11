import React from 'react';
import { fire } from '@utils';
import type { FeatureCollection } from 'geojson';

import ComboAdresseSearch from '../../ComboAdresseSearch';
import { ComboSearchProps } from '~/components/ComboSearch';

export function AddressInput(
  comboProps: Pick<
    ComboSearchProps,
    'screenReaderInstructions' | 'announceTemplateId'
  > & { featureCollection: FeatureCollection; champId: string }
) {
  return (
    <div
      style={{
        marginBottom: '10px'
      }}
    >
      <ComboAdresseSearch
        className="fr-input fr-mt-1w"
        allowInputValues={false}
        id={comboProps.champId}
        onChange={(_, feature) => {
          fire(document, 'map:zoom', {
            featureCollection: comboProps.featureCollection,
            feature
          });
        }}
        {...comboProps}
      />
    </div>
  );
}
