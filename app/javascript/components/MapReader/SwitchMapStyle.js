import React from 'react';
import ortho from '../MapStyles/images/preview-ortho.png';
import vector from '../MapStyles/images/preview-vector.png';
import PropTypes from 'prop-types';

const SwitchMapStyle = ({ isVector }) => {
  const style = isVector ? 'Satellite' : 'Vectoriel';
  const source = `${isVector ? ortho : vector}`;

  const imgStyle = {
    width: '100%',
    height: '100%',
    cursor: 'pointer'
  };

  const textStyle = {
    position: 'relative',
    bottom: '26px',
    left: '4px',
    color: `${isVector ? '#fff' : '#000'}`
  };
  return (
    <div className="switch-style mapboxgl-ctrl-swith-map-style">
      <img alt={style} style={imgStyle} src={source} />
      <div className="text" style={textStyle}>
        {style}
      </div>
    </div>
  );
};

SwitchMapStyle.propTypes = {
  isVector: PropTypes.bool
};

export default SwitchMapStyle;
