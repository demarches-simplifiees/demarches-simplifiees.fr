import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampDateOption({ label, handler }) {
  return (
    <div className="constraints">
      <label htmlFor={handler.id}>
        {label}
        <input
          type="date"
          id={handler.id}
          value={handler.value}
          name={handler.name}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </label>
    </div>
  );
}

TypeDeChampDateOption.propTypes = {
  label: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampDateOption;
