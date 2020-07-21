import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampLevelOption({ label, handler }) {
  return (
    <label htmlFor={handler.id}>
      {label}
      <input
        type="number"
        id={handler.id}
        value={handler.value ? handler.value : '1'}
        name={handler.name}
        onChange={handler.onChange}
        className="small-margin small"
        min="1"
        max="3"
      />
    </label>
  );
}

TypeDeChampLevelOption.propTypes = {
  label: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampLevelOption;
