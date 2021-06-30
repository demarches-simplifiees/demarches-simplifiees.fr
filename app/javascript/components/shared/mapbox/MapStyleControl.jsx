import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { Popover, RadioGroup } from '@headlessui/react';
import { usePopper } from 'react-popper';
import { MapIcon } from '@heroicons/react/outline';

import { getMapStyle, getLayerName } from './styles';

const STYLES = {
  ortho: 'Satellite',
  vector: 'Vectoriel',
  ign: 'Carte IGN'
};

function optionalLayersMap(optionalLayers) {
  return Object.fromEntries(
    optionalLayers
      .filter((layer) => layer != 'cadastres')
      .map((layer) => [layer, { enabled: true, opacity: 100 }])
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
  const style = useMemo(
    () =>
      getMapStyle(
        styleId,
        enabledLayers.map(([layer]) => layer)
      ),
    [
      styleId,
      enabledLayers.map(([layer, { opacity }]) => `${layer}-${opacity}`)
    ]
  );

  useEffect(() => onStyleChange(), [styleId, cadastreEnabled]);

  return { style, layers, setStyle, setLayerEnabled, setLayerOpacity };
}

function MapStyleControl({ style, layers, setStyle, setLayerEnabled }) {
  const [buttonElement, setButtonElement] = useState();
  const [panelElement, setPanelElement] = useState();
  const { styles, attributes } = usePopper(buttonElement, panelElement, {
    placement: 'bottom-end'
  });

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
          {Object.keys(layers).length ? (
            <ul className="layers-list">
              {Object.entries(layers).map(([layer, { enabled }]) => (
                <li key={layer} className="flex">
                  <input
                    className="m-0 p-0 mr-1"
                    type="checkbox"
                    checked={enabled}
                    onChange={(event) => {
                      setLayerEnabled(layer, event.target.checked);
                    }}
                  />
                  <label>{getLayerName(layer)}</label>
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
