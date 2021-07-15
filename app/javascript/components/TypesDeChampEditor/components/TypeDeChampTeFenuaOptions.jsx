import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampTeFenuaOptions({ isVisible, children }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label>Utilisation de la cartographie</label>
        <div className="TeFenua-options">{children}</div>
      </div>
    );
  }
  return null;
}

TypeDeChampTeFenuaOptions.propTypes = {
  isVisible: PropTypes.bool,
  children: PropTypes.array
};

export default TypeDeChampTeFenuaOptions;
