import { useCallback, useRef, useEffect, useMemo } from 'react';
import mapboxgl, { Popup } from 'mapbox-gl';

import {
  filterFeatureCollection,
  findFeature,
  getBounds,
  getCenter
} from '../shared/mapbox/utils';

const SOURCE_CADASTRE = 'cadastre';

export function useMapbox(featureCollection) {
  const mapRef = useRef();
  const selectedCadastresRef = useRef(() => new Set());
  const isSupported = useMemo(() => mapboxgl.supported());

  const fitBounds = useCallback((bbox) => {
    mapRef.current.fitBounds(bbox, { padding: 100 });
  }, []);

  const onLoad = useCallback(
    (map) => {
      if (!mapRef.current) {
        mapRef.current = map;
        mapRef.current.fitBounds(featureCollection.bbox, { padding: 100 });
        onStyleChange();
      }
    },
    [featureCollection]
  );

  const onStyleChange = useCallback(() => {
    if (mapRef.current) {
      selectedCadastresRef.current = new Set(
        filterFeatureCollection(
          featureCollection,
          SOURCE_CADASTRE
        ).features.map(({ properties }) => properties.cid)
      );
      if (selectedCadastresRef.current.size > 0) {
        mapRef.current.setFilter('parcelle-highlighted', [
          'in',
          'id',
          ...selectedCadastresRef.current
        ]);
      }
    }
  }, [featureCollection]);

  const popup = useMemo(
    () =>
      new Popup({
        closeButton: false,
        closeOnClick: false
      })
  );

  const onMouseEnter = useCallback(
    (event) => {
      const feature = event.features[0];
      if (feature.properties && feature.properties.description) {
        const coordinates = getCenter(feature.geometry, event.lngLat);
        const description = feature.properties.description;
        mapRef.current.getCanvas().style.cursor = 'pointer';
        popup.setLngLat(coordinates).setHTML(description).addTo(mapRef.current);
      } else {
        popup.remove();
      }
    },
    [popup]
  );

  const onMouseLeave = useCallback(() => {
    mapRef.current.getCanvas().style.cursor = '';
    popup.remove();
  }, [popup]);

  useExternalEvents(featureCollection, { fitBounds });

  return { isSupported, onLoad, onStyleChange, onMouseEnter, onMouseLeave };
}

function useExternalEvents(featureCollection, { fitBounds }) {
  const onFeatureFocus = useCallback(
    ({ detail }) => {
      const { id } = detail;
      const feature = findFeature(featureCollection, id);
      if (feature) {
        fitBounds(getBounds(feature.geometry));
      }
    },
    [featureCollection, fitBounds]
  );

  useEvent('map:feature:focus', onFeatureFocus);
}

export function useEvent(eventName, callback) {
  return useEffect(() => {
    addEventListener(eventName, callback);
    return () => removeEventListener(eventName, callback);
  }, [eventName, callback]);
}
