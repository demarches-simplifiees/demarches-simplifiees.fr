import React from 'react';

import { groupId } from './shared/hooks';
import ComboMultiple, { ComboMultipleProps } from './ComboMultiple';

export default function ComboMultipleDropdownList({
  id,
  ...props
}: ComboMultipleProps & { id: string }) {
  return <ComboMultiple id={id} {...props} group={groupId(id)} />;
}
