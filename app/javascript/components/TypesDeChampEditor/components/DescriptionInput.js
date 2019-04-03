import React from 'react';
import PropTypes from 'prop-types';

function DescriptionInput({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Description</label>
        <textarea
          id={handler.id}
          name={handler.name}
          value={handler.value || ''}
          onChange={handler.onChange}
          rows={3}
          cols={40}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

DescriptionInput.propTypes = {
  isVisible: PropTypes.bool,
  handler: PropTypes.object
};

export default DescriptionInput;
