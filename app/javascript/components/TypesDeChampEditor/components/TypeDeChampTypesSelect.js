import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampTypesSelect({ handler, options }) {
  return (
    <div className="cell">
      <select
        id={handler.id}
        name={handler.name}
        onChange={handler.onChange}
        value={handler.value}
        className="small-margin small inline"
      >
        {options.map(([label, key]) => (
          <option key={key} value={key}>
            {label}
          </option>
        ))}
      </select>
    </div>
  );
}

TypeDeChampTypesSelect.propTypes = {
  handler: PropTypes.object,
  options: PropTypes.array
};

export default TypeDeChampTypesSelect;
