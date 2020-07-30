import React from 'react';
import ortho from './images/preview-ortho.png';
import vector from './images/preview-vector.png';
import PropTypes from 'prop-types';

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
  }
};

const IGN_STYLES = {
  ...STYLES,
  ign: {
    title: 'Carte IGN',
    preview: vector,
    color: '#000'
  }
};

function getNextStyle(style, ign) {
  const styles = Object.keys(ign ? IGN_STYLES : STYLES);
  let index = styles.indexOf(style) + 1;
  if (index === styles.length) {
    return styles[0];
  }
  return styles[index];
}

export const SwitchMapStyle = ({ style, setStyle, ign }) => {
  const nextStyle = getNextStyle(style, ign);
  const { title, preview, color } = (ign ? IGN_STYLES : STYLES)[nextStyle];

  const imgStyle = {
    width: '100%',
    height: '100%',
    cursor: 'pointer'
  };

  const textStyle = {
    position: 'relative',
    bottom: '26px',
    left: '4px',
    color
  };

  return (
    <div
      className="style-switch"
      style={{
        position: 'absolute',
        bottom: 0,
        left: 0
      }}
      onClick={() => setStyle(nextStyle)}
    >
      <div className="switch-style mapboxgl-ctrl-swith-map-style">
        <img alt={title} style={imgStyle} src={preview} />
        <div className="text" style={textStyle}>
          {title}
        </div>
      </div>
    </div>
  );
};

SwitchMapStyle.propTypes = {
  style: PropTypes.string,
  setStyle: PropTypes.func,
  ign: PropTypes.bool
};
