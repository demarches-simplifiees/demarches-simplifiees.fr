import React, {
  useState,
  useContext,
  useRef,
  useEffect,
  useMemo,
  ReactNode,
  createContext
} from 'react';
import maplibre, { Map, Style, NavigationControl } from 'maplibre-gl';

import invariant from 'tiny-invariant';

import { useStyle } from './hooks';
import { StyleControl } from './StyleControl';

const Context = createContext<{ map?: Map | null }>({});

type MapLibreProps = {
  layers: string[];
  header?: ReactNode;
  footer?: ReactNode;
  children: ReactNode;
};

export function useMapLibre() {
  const context = useContext(Context);
  invariant(context.map, 'Maplibre not initialized');
  return context.map;
}

export function MapLibre({ children, header, footer, layers }: MapLibreProps) {
  const isSupported = useMemo(
    () => maplibre.supported({ failIfMajorPerformanceCaveat: true }) && !isIE(),
    []
  );
  const containerRef = useRef<HTMLDivElement>(null);
  const [map, setMap] = useState<Map | null>();

  const onStyleChange = (style: Style) => {
    if (map) {
      map.setStyle(style);
    }
  };
  const { style, ...mapStyleProps } = useStyle(layers, onStyleChange);

  useEffect(() => {
    if (isSupported && !map) {
      invariant(containerRef.current, 'Map container not found');
      const map = new Map({
        container: containerRef.current,
        style
      });
      map.addControl(new NavigationControl({}), 'top-right');
      map.on('load', () => {
        setMap(map);
      });
    }
  }, []);

  if (!isSupported) {
    return (
      <div
        style={{ marginBottom: '20px' }}
        className="outdated-browser-banner site-banner"
      >
        <div className="container">
          <div className="site-banner-icon">⚠️</div>
          <div className="site-banner-text">
            Nous ne pouvons pas afficher la carte car elle est imcompatible avec
            votre navigateur. Nous vous conseillons de le mettre à jour ou
            d’utiliser{' '}
            <a
              href="https://browser-update.org/fr/update.html"
              target="_blank"
              rel="noopener noreferrer"
            >
              un navigateur plus récent
            </a>
            .
          </div>
        </div>
      </div>
    );
  }

  return (
    <Context.Provider value={{ map }}>
      {map ? header : null}
      <div ref={containerRef} style={{ height: '500px' }}>
        <StyleControl styleId={style.id} {...mapStyleProps} />
        {map ? children : null}
      </div>
      {map ? footer : null}
    </Context.Provider>
  );
}

function isIE() {
  const ua = window.navigator.userAgent;
  const msie = ua.indexOf('MSIE ');
  const trident = ua.indexOf('Trident/');
  return msie > 0 || trident > 0;
}
