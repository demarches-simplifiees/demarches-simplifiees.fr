import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampDropDownOther({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>
          <input
            type="checkbox"
            id={handler.id}
            name={handler.name}
            checked={!!handler.value}
            onChange={handler.onChange}
            className="small-margin small"
          />
          Proposer une option &apos;autre&apos; avec un texte libre
        </label>
      </div>
    );
  }
  return null;
}

TypeDeChampDropDownOther.propTypes = {
  isVisible: PropTypes.bool,
  handler: PropTypes.object
};

export default TypeDeChampDropDownOther;
