import React from 'react';
import { fire } from '@utils';

import ComboAdresseSearch from '../../ComboAdresseSearch';
import { ComboSearchProps } from '~/components/ComboSearch';

export function AddressInput(
  comboProps: Pick<
    ComboSearchProps,
    'screenReaderInstructions' | 'announceTemplateId'
  >
) {
  return (
    <div
      style={{
        marginBottom: '10px'
      }}
    >
      <ComboAdresseSearch
        className="no-margin"
        placeholder="Rechercher une adresse : saisissez au moins 2 caractères"
        allowInputValues={false}
        onChange={(_, feature) => {
          fire(document, 'map:zoom', { feature });
        }}
        {...comboProps}
      />
    </div>
  );
}
