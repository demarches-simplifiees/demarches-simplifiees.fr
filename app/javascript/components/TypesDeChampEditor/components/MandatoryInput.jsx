import React from 'react';
import PropTypes from 'prop-types';

function MandatoryInput({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Obligatoire</label>
        <input
          type="checkbox"
          id={handler.id}
          name={handler.name}
          checked={!!handler.value}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

MandatoryInput.propTypes = {
  handler: PropTypes.object,
  isVisible: PropTypes.bool
};

export default MandatoryInput;
