import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { Popover, RadioGroup } from '@headlessui/react';
import { usePopper } from 'react-popper';
import { MapIcon } from '@heroicons/react/outline';
import { Slider } from '@reach/slider';
import { useId } from '@reach/auto-id';
import '@reach/slider/styles.css';

import { getMapStyle, getLayerName, NBS } from './styles';

const STYLES = {
  ortho: 'Satellite',
  vector: 'Vectoriel',
  ign: 'Carte IGN'
};

function optionalLayersMap(optionalLayers) {
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

export function useMapStyle(
  optionalLayers,
  { onStyleChange, cadastreEnabled }
) {
  const [styleId, setStyle] = useState('ortho');
  const [layers, setLayers] = useState(() => optionalLayersMap(optionalLayers));
  const setLayerEnabled = (layer, enabled) =>
    setLayers((optionalLayers) => {
      optionalLayers[layer].enabled = enabled;
      return { ...optionalLayers };
    });
  const setLayerOpacity = (layer, opacity) =>
    setLayers((optionalLayers) => {
      optionalLayers[layer].opacity = opacity;
      return { ...optionalLayers };
    });
  const enabledLayers = Object.entries(layers).filter(
    ([, { enabled }]) => enabled
  );
  const layerIds = enabledLayers.map(
    ([layer, { opacity }]) => `${layer}-${opacity}`
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
    [styleId, layerIds]
  );

  useEffect(() => onStyleChange(), [styleId, layerIds, cadastreEnabled]);

  return { style, layers, setStyle, setLayerEnabled, setLayerOpacity };
}

function MapStyleControl({
  style,
  layers,
  setStyle,
  setLayerEnabled,
  setLayerOpacity
}) {
  const [buttonElement, setButtonElement] = useState();
  const [panelElement, setPanelElement] = useState();
  const { styles, attributes } = usePopper(buttonElement, panelElement, {
    placement: 'bottom-end'
  });
  const configurableLayers = Object.entries(layers).filter(
    ([, { configurable }]) => configurable
  );
  const mapId = useId();

  return (
    <div className="form map-style-control mapboxgl-ctrl-group">
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
            value={style}
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

MapStyleControl.propTypes = {
  style: PropTypes.string,
  layers: PropTypes.object,
  setStyle: PropTypes.func,
  setLayerEnabled: PropTypes.func,
  setLayerOpacity: PropTypes.func
};

export default MapStyleControl;
