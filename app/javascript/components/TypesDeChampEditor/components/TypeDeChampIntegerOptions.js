import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampIntegerOptions({ isVisible, children }) {
  if (isVisible) {
    return (
      <div className="flex justify-start cell constraints">
        <label>Bornes</label>
        {children}
      </div>
    );
  }
  return null;
}

TypeDeChampIntegerOptions.propTypes = {
  isVisible: PropTypes.bool,
  children: PropTypes.array
};

export default TypeDeChampIntegerOptions;
