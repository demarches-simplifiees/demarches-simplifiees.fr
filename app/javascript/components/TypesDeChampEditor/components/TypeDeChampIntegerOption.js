import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampIntegerOption({ label, handler }) {
  return (
    <label htmlFor={handler.id}>
      {label}
      <input
        type="number"
        id={handler.id}
        value={handler.value}
        name={handler.name}
        onChange={handler.onChange}
        className="small-margin small"
      />
    </label>
  );
}

TypeDeChampIntegerOption.propTypes = {
  label: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampIntegerOption;
