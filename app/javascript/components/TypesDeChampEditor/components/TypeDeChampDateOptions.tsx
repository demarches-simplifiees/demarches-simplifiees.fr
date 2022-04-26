import React from 'react';

export function TypeDeChampDateOptions({
  isVisible,
  children
}: {
  isVisible: boolean;
  children: JSX.Element[];
}) {
  if (isVisible) {
    return (
      <div className="flex justify-start cell constraints">
        <label>Période</label>
        {children}
      </div>
    );
  }
  return null;
}
