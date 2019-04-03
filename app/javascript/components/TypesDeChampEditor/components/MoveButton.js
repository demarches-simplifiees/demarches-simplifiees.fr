import React from 'react';
import PropTypes from 'prop-types';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

function MoveButton({ isEnabled, icon, onClick }) {
  return (
    <button className="button small icon-only move" disabled={!isEnabled} onClick={onClick}>
      <FontAwesomeIcon icon={icon} />
    </button>
  );
}

MoveButton.propTypes = {
  isEnabled: PropTypes.bool,
  icon: PropTypes.string,
  onClick: PropTypes.func
};

export default MoveButton;
