import React from 'react';
import PropTypes from 'prop-types';

import { groupId } from './shared/hooks';
import ComboMultiple from './ComboMultiple';

function ComboMultipleDropdownList({ id, ...props }) {
  return <ComboMultiple group={groupId(id)} id={id} {...props} />;
}

ComboMultipleDropdownList.propTypes = {
  id: PropTypes.string
};

export default ComboMultipleDropdownList;
