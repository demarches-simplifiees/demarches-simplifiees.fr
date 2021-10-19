import React from 'react';
import PropTypes from 'prop-types';

export default function TypeDeChampDropDownSecondary({
  isVisible,
  libelleHandler,
  descriptionHandler
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={libelleHandler.id}>Libellé secondaire</label>
        <input
          type="text"
          id={libelleHandler.id}
          name={libelleHandler.name}
          value={libelleHandler.value ?? ''}
          onChange={libelleHandler.onChange}
          className="small-margin small"
        />
        <label htmlFor={descriptionHandler.id}>Description secondaire</label>
        <textarea
          id={descriptionHandler.id}
          name={descriptionHandler.name}
          value={descriptionHandler.value ?? ''}
          onChange={descriptionHandler.onChange}
          rows={3}
          cols={40}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

TypeDeChampDropDownSecondary.propTypes = {
  isVisible: PropTypes.bool,
  libelleHandler: PropTypes.object,
  descriptionHandler: PropTypes.object
};
