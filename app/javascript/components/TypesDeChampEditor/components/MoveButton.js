import React from 'react';
import PropTypes from 'prop-types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

function MoveButton({ isVisible, icon, onClick }) {
  if (isVisible) {
    return (
      <button className="button small icon-only move" onClick={onClick}>
        <FontAwesomeIcon icon={icon} />
      </button>
    );
  }
  return null;
}

MoveButton.propTypes = {
  isVisible: PropTypes.bool,
  icon: PropTypes.string,
  onClick: PropTypes.func
};

export default MoveButton;
