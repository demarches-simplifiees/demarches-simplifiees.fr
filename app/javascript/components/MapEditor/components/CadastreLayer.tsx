import { useCallback, useRef } from 'react';
import type { Feature, FeatureCollection } from 'geojson';

import { useMapLibre } from '../../shared/maplibre/MapLibre';
import {
  useEvent,
  useMapEvent,
  EventHandler
} from '../../shared/maplibre/hooks';
import {
  filterFeatureCollection,
  findFeature
} from '../../shared/maplibre/utils';

import { SOURCE_CADASTRE, CreateFeatures, DeleteFeatures } from '../hooks';

export function CadastreLayer({
  featureCollection,
  createFeatures,
  deleteFeatures,
  enabled
}: {
  featureCollection: FeatureCollection;
  createFeatures: CreateFeatures;
  deleteFeatures: DeleteFeatures;
  enabled: boolean;
}) {
  const map = useMapLibre();
  const selectedCadastresRef = useRef(new Set<string>());

  const highlightFeature = useCallback(
    (cid: string, highlight: boolean) => {
      if (highlight) {
        selectedCadastresRef.current.add(cid);
      } else {
        selectedCadastresRef.current.delete(cid);
      }
      if (selectedCadastresRef.current.size == 0) {
        map.setFilter('parcelle-highlighted', ['in', 'id', '']);
      } else {
        map.setFilter('parcelle-highlighted', [
          'in',
          'id',
          ...selectedCadastresRef.current
        ]);
      }
    },
    [map]
  );

  const hoverFeature = useCallback(
    (feature: Feature, hover: boolean) => {
      if (!selectedCadastresRef.current.has(feature.properties?.id)) {
        map.setFeatureState(
          {
            source: 'cadastre',
            sourceLayer: 'parcelles',
            id: String(feature.id)
          },
          { hover }
        );
      }
    },
    [map]
  );

  useCadastres(featureCollection, {
    hoverFeature,
    createFeatures,
    deleteFeatures,
    enabled
  });

  useMapEvent('styledata', () => {
    selectedCadastresRef.current = new Set(
      filterFeatureCollection(featureCollection, SOURCE_CADASTRE).features.map(
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

  const onHighlight = useCallback(
    ({ detail }: CustomEvent<{ cid: string; highlight: boolean }>) => {
      highlightFeature(detail.cid, detail.highlight);
    },
    [highlightFeature]
  );

  useEvent('map:internal:cadastre:highlight', onHighlight);

  return null;
}

function useCadastres(
  featureCollection: FeatureCollection,
  {
    enabled,
    hoverFeature,
    createFeatures,
    deleteFeatures
  }: {
    enabled: boolean;
    hoverFeature: (feature: Feature, flag: boolean) => void;
    createFeatures: CreateFeatures;
    deleteFeatures: DeleteFeatures;
  }
) {
  const hoveredFeature = useRef<Feature | null>();

  const onMouseMove = useCallback<EventHandler>(
    (event) => {
      if (enabled && event.features && event.features.length > 0) {
        const feature = event.features[0];
        if (hoveredFeature.current?.id != feature.id) {
          if (hoveredFeature.current) {
            hoverFeature(hoveredFeature.current, false);
          }
          hoveredFeature.current = feature;
          hoverFeature(feature, true);
        }
      }
    },
    [enabled, hoverFeature]
  );

  const onMouseLeave = useCallback<EventHandler>(() => {
    if (hoveredFeature.current) {
      hoverFeature(hoveredFeature.current, false);
    }
    hoveredFeature.current = null;
  }, [hoverFeature]);

  const onClick = useCallback<EventHandler>(
    async (event) => {
      if (enabled && event.features && event.features.length > 0) {
        const currentId = event.features[0].properties?.id;
        const feature = findFeature(
          filterFeatureCollection(featureCollection, SOURCE_CADASTRE),
          currentId,
          'cid'
        );
        if (feature) {
          deleteFeatures({
            features: [feature],
            source: SOURCE_CADASTRE,
            external: true
          });
        } else {
          createFeatures({
            features: event.features,
            source: SOURCE_CADASTRE,
            external: true
          });
        }
      }
    },
    [enabled, featureCollection, createFeatures, deleteFeatures]
  );

  useMapEvent('click', onClick, 'parcelles-fill');
  useMapEvent('mousemove', onMouseMove, 'parcelles-fill');
  useMapEvent('mouseleave', onMouseLeave, 'parcelles-fill');
}
