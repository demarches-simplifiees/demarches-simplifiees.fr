import React, { ReactNode } from 'react';
import { SortableContainer as SortableContainerWrapper } from 'react-sortable-hoc';

export const SortableContainer = SortableContainerWrapper(
  ({ children }: { children: ReactNode }) => {
    return <ul>{children}</ul>;
  }
);

export function addChampLabel(isAnnotation: boolean) {
  if (isAnnotation) {
    return 'Ajouter une annotation';
  } else {
    return 'Ajouter un champ';
  }
}
