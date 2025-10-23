import { useEffect, useCallback } from 'react';
import type { FeatureCollection } from 'geojson';

import { useMapLibre } from '../../shared/maplibre/MapLibre';
import { useMapEvent } from '../../shared/maplibre/hooks';
import { filterFeatureCollection } from '../../shared/maplibre/utils';

export function ParcelleLayer({
  source,
  featureCollection
}: {
  source: 'rpg' | 'cadastre';
  featureCollection: FeatureCollection;
}) {
  const map = useMapLibre();
  const cidProperty = source == 'rpg' ? 'ID_PARCEL' : 'id';

  const render = useCallback(() => {
    const selectedCadastreIds = new Set(
      filterFeatureCollection(featureCollection, source).features.map(
        ({ properties }) => properties?.cid
      )
    );

    if (selectedCadastreIds.size > 0) {
      map.setFilter('parcelle-highlighted', [
        'in',
        cidProperty,
        ...selectedCadastreIds
      ]);
    }
  }, [map, source, cidProperty, featureCollection]);

  useEffect(render, [render]);
  useMapEvent('styledata', render);

  return null;
}
