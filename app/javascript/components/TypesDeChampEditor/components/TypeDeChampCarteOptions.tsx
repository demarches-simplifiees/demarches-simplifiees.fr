import React, { ReactNode } from 'react';

export function TypeDeChampCarteOptions({
  isVisible,
  children
}: {
  isVisible: boolean;
  children: ReactNode;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label>Utilisation de la cartographie</label>
        <div className="carte-options">{children}</div>
      </div>
    );
  }
  return null;
}
