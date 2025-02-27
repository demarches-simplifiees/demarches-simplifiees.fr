import { useRef } from 'react';
import type { FeatureCollection } from 'geojson';

import { useMapLibre } from '../../shared/maplibre/MapLibre';
import { useMapEvent } from '../../shared/maplibre/hooks';
import { filterFeatureCollection } from '../../shared/maplibre/utils';

export function CadastreLayer({
  featureCollection
}: {
  featureCollection: FeatureCollection;
}) {
  const map = useMapLibre();
  const selectedCadastresRef = useRef<Set<string>>(null);

  useMapEvent('styledata', () => {
    selectedCadastresRef.current = new Set(
      filterFeatureCollection(featureCollection, 'cadastre').features.map(
        ({ properties }) => properties?.cid
      )
    );
    if (selectedCadastresRef.current.size > 0) {
      map.setFilter('parcelle-highlighted', [
        'in',
        'id',
        ...selectedCadastresRef.current
      ]);
    }
  });

  return null;
}
