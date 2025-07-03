import { useEffect, useCallback } from 'react';
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

  const render = useCallback(() => {
    const selectedCadastreIds = new Set(
      filterFeatureCollection(featureCollection, 'cadastre').features.map(
        ({ properties }) => properties?.cid
      )
    );

    if (selectedCadastreIds.size > 0) {
      map.setFilter('parcelle-highlighted', [
        'in',
        'id',
        ...selectedCadastreIds
      ]);
    }
  }, [map, featureCollection]);

  useEffect(render, [render]);
  useMapEvent('styledata', render);

  return null;
}
