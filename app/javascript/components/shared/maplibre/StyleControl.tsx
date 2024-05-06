import { useState, useId } from 'react';
import { Popover, RadioGroup } from '@headlessui/react';
import { usePopper } from 'react-popper';
import { MapIcon } from '@heroicons/react/outline';
import { Slider } from '@reach/slider';
import '@reach/slider/styles.css';

import { LayersMap, NBS } from './styles';

const STYLES = {
  ortho: 'Satellite',
  vector: 'Vectoriel',
  ign: 'Carte IGN'
};

export function StyleControl({
  styleId,
  layers,
  setStyle,
  setLayerEnabled,
  setLayerOpacity
}: {
  styleId: string;
  setStyle: (style: string) => void;
  layers: LayersMap;
  setLayerEnabled: (layer: string, enabled: boolean) => void;
  setLayerOpacity: (layer: string, opacity: number) => void;
}) {
  const [buttonElement, setButtonElement] =
    useState<HTMLButtonElement | null>();
  const [panelElement, setPanelElement] = useState<HTMLDivElement | null>();
  const { styles, attributes } = usePopper(buttonElement, panelElement, {
    placement: 'bottom-end'
  });
  const configurableLayers = Object.entries(layers).filter(
    ([, { configurable }]) => configurable
  );
  const mapId = useId();

  return (
    <div
      className="form map-style-control mapboxgl-ctrl-group"
      style={{ zIndex: 10 }}
    >
      <Popover>
        <Popover.Button
          ref={setButtonElement}
          className="map-style-button"
          title="Sélectionner les couches cartographiques"
        >
          <MapIcon className="icon-size" />
        </Popover.Button>
        <Popover.Panel
          className="flex map-style-panel mapboxgl-ctrl-group"
          ref={setPanelElement}
          style={styles.popper}
          {...attributes.popper}
        >
          <RadioGroup
            value={styleId}
            onChange={setStyle}
            className="styles-list"
            as="ul"
          >
            {Object.entries(STYLES).map(([style, title]) => (
              <RadioGroup.Option
                key={style}
                value={style}
                as="li"
                className="flex"
              >
                {({ checked }) => (
                  <>
                    <input
                      type="radio"
                      key={`${style}-${checked}`}
                      defaultChecked={checked}
                      name="map-style"
                      className="m-0 p-0 mr-1"
                    />
                    <RadioGroup.Label>
                      {title.replace(/\s/g, ' ')}
                    </RadioGroup.Label>
                  </>
                )}
              </RadioGroup.Option>
            ))}
          </RadioGroup>
          {configurableLayers.length ? (
            <ul className="layers-list">
              {configurableLayers.map(([layer, { enabled, opacity, name }]) => (
                <li key={layer}>
                  <div className="flex mb-1">
                    <input
                      id={`${mapId}-${layer}`}
                      className="m-0 p-0 mr-1"
                      type="checkbox"
                      checked={enabled}
                      onChange={(event) => {
                        setLayerEnabled(layer, event.target.checked);
                      }}
                    />
                    <label className="m-0" htmlFor={`${mapId}-${layer}`}>
                      {name}
                    </label>
                  </div>
                  <Slider
                    min={10}
                    max={100}
                    step={5}
                    value={opacity}
                    onChange={(value) => {
                      setLayerOpacity(layer, value);
                    }}
                    className="mb-1"
                    title={`Réglage de l’opacité de la couche «${NBS}${name}${NBS}»`}
                    getAriaLabel={() =>
                      `Réglage de l’opacité de la couche «${NBS}${name}${NBS}»`
                    }
                    getAriaValueText={(value) =>
                      `L’opacité de la couche «${NBS}${name}${NBS}» est à ${value}${NBS}%`
                    }
                  />
                </li>
              ))}
            </ul>
          ) : null}
        </Popover.Panel>
      </Popover>
    </div>
  );
}
