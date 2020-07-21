import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampHeaderSectionOptions({ isVisible, children }) {
  if (isVisible) {
    return (
      <div className="flex justify-start cell constraints">
        <label>Options</label>
        {children}
      </div>
    );
  }
  return null;
}

TypeDeChampHeaderSectionOptions.propTypes = {
  isVisible: PropTypes.bool,
  children: PropTypes.array
};

export default TypeDeChampHeaderSectionOptions;
