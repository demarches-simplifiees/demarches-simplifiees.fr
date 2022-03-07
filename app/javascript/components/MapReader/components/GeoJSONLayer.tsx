import React, { useCallback, useEffect, useMemo } from 'react';
import { Popup, LngLatBoundsLike } from 'maplibre-gl';
import type { Feature, FeatureCollection } from 'geojson';

import { useMapLibre } from '../../shared/maplibre/MapLibre';
import {
  useFitBounds,
  useEvent,
  EventHandler,
  useMapEvent
} from '../../shared/maplibre/hooks';
import {
  filterFeatureCollection,
  findFeature,
  getBounds,
  getCenter,
  filterFeatureCollectionByGeometryType
} from '../../shared/maplibre/utils';

export function GeoJSONLayer({
  featureCollection
}: {
  featureCollection: FeatureCollection;
}) {
  const map = useMapLibre();
  const popup = useMemo(
    () =>
      new Popup({
        closeButton: false,
        closeOnClick: false
      }),
    []
  );

  const onMouseEnter = useCallback<EventHandler>(
    (event) => {
      const feature = event.features && event.features[0];
      if (feature?.properties && feature.properties.description) {
        const coordinates = getCenter(feature.geometry, event.lngLat);
        const description = feature.properties.description;
        map.getCanvas().style.cursor = 'pointer';
        popup.setLngLat(coordinates).setHTML(description).addTo(map);
      } else {
        popup.remove();
      }
    },
    [popup]
  );

  const onMouseLeave = useCallback(() => {
    map.getCanvas().style.cursor = '';
    popup.remove();
  }, [popup]);

  useExternalEvents(featureCollection);

  const polygons = filterFeatureCollectionByGeometryType(
    filterFeatureCollection(featureCollection, 'selection_utilisateur'),
    'Polygon'
  );
  const lines = filterFeatureCollectionByGeometryType(
    filterFeatureCollection(featureCollection, 'selection_utilisateur'),
    'LineString'
  );
  const points = filterFeatureCollectionByGeometryType(
    filterFeatureCollection(featureCollection, 'selection_utilisateur'),
    'Point'
  );

  return (
    <>
      {polygons.features.map((feature) => (
        <PolygonLayer
          key={feature.properties?.id}
          feature={feature}
          onMouseEnter={onMouseEnter}
          onMouseLeave={onMouseLeave}
        />
      ))}
      {lines.features.map((feature) => (
        <LineStringLayer
          key={feature.properties?.id}
          feature={feature}
          onMouseEnter={onMouseEnter}
          onMouseLeave={onMouseLeave}
        />
      ))}
      {points.features.map((feature) => (
        <PointLayer
          key={feature.properties?.id}
          feature={feature}
          onMouseEnter={onMouseEnter}
          onMouseLeave={onMouseLeave}
        />
      ))}
    </>
  );
}

function useExternalEvents(featureCollection: FeatureCollection) {
  const fitBounds = useFitBounds();
  const onFeatureFocus = useCallback(({ detail }) => {
    const { id } = detail;
    const feature = findFeature(featureCollection, id);
    if (feature) {
      fitBounds(getBounds(feature.geometry));
    }
  }, []);

  useEffect(() => {
    fitBounds(featureCollection.bbox as LngLatBoundsLike);
  }, []);

  useEvent('map:feature:focus', onFeatureFocus);
}

function LineStringLayer({
  feature,
  onMouseEnter,
  onMouseLeave
}: {
  feature: Feature;
  onMouseEnter: EventHandler;
  onMouseLeave: EventHandler;
}) {
  const map = useMapLibre();
  const sourceId = String(feature.properties?.id);
  const layerId = `${sourceId}-layer`;

  useEffect(() => {
    map
      .addSource(sourceId, {
        type: 'geojson',
        data: feature
      })
      .addLayer({
        id: layerId,
        source: sourceId,
        type: 'line',
        paint: lineStringSelectionLine
      });
  }, []);

  useMapEvent('mouseenter', onMouseEnter, layerId);
  useMapEvent('mouseleave', onMouseLeave, layerId);

  return null;
}

function PointLayer({
  feature,
  onMouseEnter,
  onMouseLeave
}: {
  feature: Feature;
  onMouseEnter: EventHandler;
  onMouseLeave: EventHandler;
}) {
  const map = useMapLibre();
  const sourceId = String(feature.properties?.id);
  const layerId = `${sourceId}-layer`;

  useEffect(() => {
    map
      .addSource(sourceId, {
        type: 'geojson',
        data: feature
      })
      .addLayer({
        id: layerId,
        source: sourceId,
        type: 'circle',
        paint: pointSelectionCircle
      });
  }, []);

  useMapEvent('mouseenter', onMouseEnter, layerId);
  useMapEvent('mouseleave', onMouseLeave, layerId);

  return null;
}

function PolygonLayer({
  feature,
  onMouseEnter,
  onMouseLeave
}: {
  feature: Feature;
  onMouseEnter: EventHandler;
  onMouseLeave: EventHandler;
}) {
  const map = useMapLibre();
  const sourceId = String(feature.properties?.id);
  const layerId = `${sourceId}-layer`;
  const lineLayerId = `${sourceId}-line-layer`;

  useEffect(() => {
    map
      .addSource(sourceId, {
        type: 'geojson',
        data: feature
      })
      .addLayer({
        id: lineLayerId,
        source: sourceId,
        type: 'line',
        paint: polygonSelectionLine
      })
      .addLayer({
        id: layerId,
        source: sourceId,
        type: 'fill',
        paint: polygonSelectionFill
      });
  }, []);

  useMapEvent('mouseenter', onMouseEnter, layerId);
  useMapEvent('mouseleave', onMouseLeave, layerId);

  return null;
}

const polygonSelectionFill = {
  'fill-color': '#EC3323',
  'fill-opacity': 0.5
};
const polygonSelectionLine = {
  'line-color': 'rgba(255, 0, 0, 1)',
  'line-width': 4
};
const lineStringSelectionLine = {
  'line-color': 'rgba(55, 42, 127, 1.00)',
  'line-width': 3
};
const pointSelectionCircle = {
  'circle-color': '#EC3323'
};
