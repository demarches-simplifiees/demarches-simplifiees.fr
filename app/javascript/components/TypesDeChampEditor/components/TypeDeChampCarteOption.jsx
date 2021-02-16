import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampCarteOption({ label, handler }) {
  return (
    <label htmlFor={handler.id}>
      <input
        type="checkbox"
        id={handler.id}
        name={handler.name}
        checked={!!handler.value}
        onChange={handler.onChange}
        className="small-margin small"
      />
      {label}
    </label>
  );
}

TypeDeChampCarteOption.propTypes = {
  label: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampCarteOption;
