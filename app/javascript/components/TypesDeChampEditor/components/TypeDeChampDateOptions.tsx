import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampDateOptions({ isVisible, children }) {
  if (isVisible) {
    return (
      <div className="flex justify-start cell constraints">
        <label>Période</label>
        {children}
      </div>
    );
  }
  return null;
}

TypeDeChampDateOptions.propTypes = {
  isVisible: PropTypes.bool,
  children: PropTypes.array
};

export default TypeDeChampDateOptions;
