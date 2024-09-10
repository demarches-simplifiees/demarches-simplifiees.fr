import {
  useCallback,
  useEffect,
  useState,
  useMemo,
  type RefObject
} from 'react';
import type {
  LngLatBoundsLike,
  LngLat,
  MapLayerEventType,
  Style,
  LngLatLike
} from 'maplibre-gl';
import type { Feature, Geometry } from 'geojson';

import { getMapStyle, getLayerName, LayersMap } from './styles';
import { useMapLibre } from './MapLibre';

export function useFitBounds() {
  const map = useMapLibre();
  return useCallback(
    (bbox: LngLatBoundsLike) => {
      map.fitBounds(bbox, { padding: 100 });
    },
    [map]
  );
}

export function useFitBoundsNoFly() {
  const map = useMapLibre();
  return useCallback(
    (bbox: LngLatBoundsLike) => {
      map.fitBounds(bbox, { padding: 100, linear: true, duration: 0 });
    },
    [map]
  );
}

export function useFlyTo() {
  const map = useMapLibre();
  return useCallback(
    (zoom: number, center: LngLatLike) => {
      map.flyTo({ zoom, center });
    },
    [map]
  );
}

export function useEvent<T>(
  eventName: string,
  callback: (event: CustomEvent<T>) => void
) {
  return useEffect(() => {
    addEventListener(eventName, callback as EventListener);
    return () => removeEventListener(eventName, callback as EventListener);
  }, [eventName, callback]);
}

export type EventHandler = (event: {
  features: Feature<Geometry>[];
  lngLat: LngLat;
}) => void;

export function useMapEvent(
  eventName: string,
  callback: EventHandler,
  target?: string
) {
  const map = useMapLibre();
  return useEffect(() => {
    if (target) {
      // event typing is hard
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      map.on(eventName as keyof MapLayerEventType, target, callback as any);
    } else {
      map.on(eventName, callback);
    }
    return () => {
      if (target) {
        // event typing is hard
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        map.off(eventName as keyof MapLayerEventType, target, callback as any);
      } else {
        map.off(eventName, callback);
      }
    };
  }, [map, eventName, target, callback]);
}

function optionalLayersMap(optionalLayers: string[]): LayersMap {
  return Object.fromEntries(
    optionalLayers.map((layer) => [
      layer,
      {
        configurable: layer != 'cadastres',
        enabled: true,
        opacity: 70,
        name: getLayerName(layer)
      }
    ])
  );
}

export function useStyle(
  optionalLayers: string[],
  onStyleChange: (style: Style) => void
) {
  const [styleId, setStyle] = useState('ortho');
  const [layers, setLayers] = useState(() => optionalLayersMap(optionalLayers));
  const setLayerEnabled = (layer: string, enabled: boolean) =>
    setLayers((optionalLayers) => {
      optionalLayers[layer].enabled = enabled;
      return { ...optionalLayers };
    });
  const setLayerOpacity = (layer: string, opacity: number) =>
    setLayers((optionalLayers) => {
      optionalLayers[layer].opacity = opacity;
      return { ...optionalLayers };
    });
  const enabledLayers = useMemo(
    () => Object.entries(layers).filter(([, { enabled }]) => enabled),
    [layers]
  );
  const style = useMemo(
    () =>
      getMapStyle(
        styleId,
        enabledLayers.map(([layer]) => layer),
        Object.fromEntries(
          enabledLayers.map(([layer, { opacity }]) => [layer, opacity])
        )
      ),
    [styleId, enabledLayers]
  );

  useEffect(() => onStyleChange(style), [onStyleChange, style]);

  return { style, layers, setStyle, setLayerEnabled, setLayerOpacity };
}

function isElementVisible(
  element: HTMLElement,
  callback: (visible: boolean) => void
) {
  if (element.offsetWidth > 0 && element.offsetHeight > 0) {
    callback(true);
  } else {
    callback(false);
    const observer = new IntersectionObserver(
      (entries) => callback(entries[0].isIntersecting == true),
      { threshold: [0] }
    );
    observer.observe(element);
    return () => observer.unobserve(element);
  }
}

export function useElementVisible(element: RefObject<HTMLElement>) {
  const [visible, setVisible] = useState(false);
  useEffect(() => {
    if (element.current) {
      return isElementVisible(element.current, setVisible);
    }
  }, [element]);
  return visible;
}
