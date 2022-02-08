import React from 'react';
import type { Point } from 'geojson';

import ComboAdresseSearch from '../../ComboAdresseSearch';
import { useFlyTo } from '../../shared/maplibre/hooks';

export function AddressInput() {
  const flyTo = useFlyTo();

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
        onChange={(_, result) => {
          const geometry = result?.geometry as Point;
          flyTo(17, geometry.coordinates as [number, number]);
        }}
      />
    </div>
  );
}
