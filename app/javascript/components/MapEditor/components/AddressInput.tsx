import React from 'react';
import { fire } from '@utils';

import ComboAdresseSearch from '../../ComboAdresseSearch';

export function AddressInput() {
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
      />
    </div>
  );
}
