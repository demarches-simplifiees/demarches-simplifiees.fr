import React from 'react';
import PropTypes from 'prop-types';
import Select from 'react-select';

function TypeDeChampTypesSelect({ handler, options }) {
  const opts = options.map(([label, value]) => ({
    label,
    value
  }));
  return (
    <div className="cell">
      <Select
        id={handler.id}
        name={handler.name}
        defaultValue={opts.find((option) => option.value == handler.value)}
        onChange={(option) => handler.onChange({ target: option })}
        options={opts}
        menuPortalTarget={document.body}
        className="react-select"
        styles={{
          control: (provided) => ({ ...provided, width: '300px' })
        }}
      />
    </div>
  );
}

TypeDeChampTypesSelect.propTypes = {
  handler: PropTypes.object,
  options: PropTypes.array
};

export default TypeDeChampTypesSelect;
