import React from 'react';
import PropTypes from 'prop-types';

function LibelleInput({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell libelle">
        <label htmlFor={handler.id}>Libellé</label>
        <input
          type="text"
          id={handler.id}
          name={handler.name}
          value={handler.value}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

LibelleInput.propTypes = {
  handler: PropTypes.object,
  isVisible: PropTypes.bool
};

export default LibelleInput;
