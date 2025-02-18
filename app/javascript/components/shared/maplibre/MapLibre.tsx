import {
  useState,
  useContext,
  useRef,
  useEffect,
  useMemo,
  type ReactNode,
  createContext,
  useCallback
} from 'react';
import { createPortal } from 'react-dom';
import { Map, NavigationControl } from 'maplibre-gl';
import type { StyleSpecification, IControl } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

import invariant from 'tiny-invariant';

import { useStyle, useElementVisible } from './hooks';
import { StyleSwitch } from './StyleControl';

const Context = createContext<{ map?: Map | null }>({});

type MapLibreProps = {
  layers: string[];
  children: ReactNode;
};

export function useMapLibre() {
  const context = useContext(Context);
  invariant(context.map, 'Maplibre not initialized');
  return context.map;
}

export function MapLibre({ children, layers }: MapLibreProps) {
  const isSupported = useMemo(() => isWebglSupported(), []);
  const containerRef = useRef<HTMLDivElement>(null);
  const visible = useElementVisible(containerRef);
  const [map, setMap] = useState<Map | null>();
  const [styleControlElement, setStyleControlElement] =
    useState<HTMLElement | null>(null);

  const onStyleChange = useCallback(
    (style: StyleSpecification) => {
      if (map) {
        map.setStyle(style);
      }
    },
    [map]
  );
  const { style, ...mapStyleProps } = useStyle(layers, onStyleChange);

  useEffect(() => {
    if (isSupported && visible && !map) {
      invariant(containerRef.current, 'Map container not found');
      const map = new Map({
        container: containerRef.current,
        style
      });
      map.addControl(new NavigationControl({}), 'top-right');
      const styleControl = new ReactControl();
      map.addControl(styleControl, 'bottom-left');
      map.on('load', () => {
        setMap(map);
        setStyleControlElement(styleControl.container);
      });
    }
  }, [map, style, visible, isSupported]);

  if (!isSupported) {
    return (
      <div
        style={{ marginBottom: '20px' }}
        className="outdated-browser-banner site-banner"
      >
        <div className="container">
          <div className="site-banner-icon">⚠️</div>
          <div className="site-banner-text">
            Nous ne pouvons pas afficher la carte car elle est incompatible avec
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
      <div ref={containerRef} style={{ height: '500px' }}>
        {styleControlElement != null
          ? createPortal(
              <StyleSwitch styleId={style.id} {...mapStyleProps} />,
              styleControlElement
            )
          : null}
        {map ? children : null}
      </div>
    </Context.Provider>
  );
}

function isWebglSupported() {
  if (window.WebGLRenderingContext) {
    const canvas = document.createElement('canvas');
    try {
      // Note that { failIfMajorPerformanceCaveat: true } can be passed as a second argument
      // to canvas.getContext(), causing the check to fail if hardware rendering is not available. See
      // https://developer.mozilla.org/en-US/docs/Web/API/HTMLCanvasElement/getContext
      // for more details.
      const context = canvas.getContext('webgl2') || canvas.getContext('webgl');
      if (context && typeof context.getParameter == 'function') {
        return true;
      }
    } catch {
      // WebGL is supported, but disabled
    }
    return false;
  }
  // WebGL not supported
  return false;
}

export class ReactControl implements IControl {
  #container: HTMLElement | null = null;

  get container(): HTMLElement | null {
    return this.#container;
  }

  onAdd(): HTMLElement {
    this.#container = document.createElement('div');
    this.#container.className = 'maplibregl-ctrl maplibregl-ctrl-group ds-ctrl';
    return this.#container;
  }

  onRemove(): void {
    this.#container?.remove();
    this.#container = null;
  }
}
