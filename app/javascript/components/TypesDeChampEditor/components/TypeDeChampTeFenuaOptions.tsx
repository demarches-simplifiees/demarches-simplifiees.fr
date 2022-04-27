import React from 'react';

export function TypeDeChampTeFenuaOptions({
  isVisible,
  children
}: {
  isVisible: boolean;
  children: JSX.Element[];
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label>Utilisation de la cartographie</label>
        <div className="TeFenua-options">{children}</div>
      </div>
    );
  }
  return null;
}
