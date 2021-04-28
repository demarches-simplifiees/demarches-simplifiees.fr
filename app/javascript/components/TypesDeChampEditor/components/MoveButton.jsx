import React from 'react';
import PropTypes from 'prop-types';
import { ArrowDownIcon, ArrowUpIcon } from '@heroicons/react/solid';

function MoveButton({ isEnabled, icon, title, onClick }) {
  return (
    <button
      className="button small move"
      disabled={!isEnabled}
      title={title}
      onClick={onClick}
    >
      {icon == 'arrow-up' ? (
        <ArrowUpIcon className="icon-size" />
      ) : (
        <ArrowDownIcon className="icon-size" />
      )}
    </button>
  );
}

MoveButton.propTypes = {
  isEnabled: PropTypes.bool,
  icon: PropTypes.string,
  title: PropTypes.string,
  onClick: PropTypes.func
};

export default MoveButton;
