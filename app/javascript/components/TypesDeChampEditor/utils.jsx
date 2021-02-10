import React from 'react';
import { sortableContainer } from 'react-sortable-hoc';

export const SortableContainer = sortableContainer(({ children }) => {
  return <ul>{children}</ul>;
});

export function addChampLabel(isAnnotation) {
  if (isAnnotation) {
    return 'Ajouter une annotation';
  } else {
    return 'Ajouter un champ';
  }
}
