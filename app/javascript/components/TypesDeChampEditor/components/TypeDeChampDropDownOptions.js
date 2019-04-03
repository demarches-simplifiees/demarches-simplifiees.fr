import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampDropDownOptions({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Liste déroulante</label>
        <textarea
          id={handler.id}
          name={handler.name}
          value={handler.value}
          onChange={handler.onChange}
          rows={3}
          cols={40}
          placeholder="Ecrire une valeur par ligne et --valeur-- pour un séparateur."
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

TypeDeChampDropDownOptions.propTypes = {
  isVisible: PropTypes.bool,
  value: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampDropDownOptions;
