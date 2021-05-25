import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';

import { getMapStyle } from './styles';
import ortho from './styles/images/preview-ortho.png';
import vector from './styles/images/preview-vector.png';

const STYLES = {
  ortho: {
    title: 'Satellite',
    preview: ortho,
    color: '#fff'
  },
  vector: {
    title: 'Vectoriel',
    preview: vector,
    color: '#000'
  },
  ign: {
    title: 'Carte IGN',
    preview: vector,
    color: '#000'
  }
};

function getNextStyle(style) {
  const styleNames = Object.keys(STYLES);
  const index = styleNames.indexOf(style) + 1;
  if (index === styleNames.length) {
    return styleNames[0];
  }
  return styleNames[index];
}

export function useMapStyle(
  optionalLayers,
  { onStyleChange, cadastreEnabled }
) {
  const [styleId, setStyle] = useState('ortho');
  const style = useMemo(() => getMapStyle(styleId, optionalLayers), [
    styleId,
    optionalLayers
  ]);

  useEffect(() => onStyleChange(), [styleId, cadastreEnabled]);

  return [style, setStyle];
}

function MapStyleControl({ style, setStyle }) {
  const nextStyle = getNextStyle(style);
  const { title, preview, color } = STYLES[nextStyle];

  return (
    <div className="map-style-control">
      <button type="button" onClick={() => setStyle(nextStyle)}>
        <img alt={title} src={preview} />
        <div style={{ color }}>{title}</div>
      </button>
    </div>
  );
}

MapStyleControl.propTypes = {
  style: PropTypes.string,
  setStyle: PropTypes.func
};

export default MapStyleControl;
