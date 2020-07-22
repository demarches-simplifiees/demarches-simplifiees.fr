import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampCarteOptions({ isVisible, children }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label>Utilisation de la cartographie</label>
        <div className="carte-options">{children}</div>
      </div>
    );
  }
  return null;
}

TypeDeChampCarteOptions.propTypes = {
  isVisible: PropTypes.bool,
  children: PropTypes.node
};

export default TypeDeChampCarteOptions;
