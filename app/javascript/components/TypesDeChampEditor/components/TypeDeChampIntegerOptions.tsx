import React from 'react';

export function TypeDeChampIntegerOptions({
  isVisible,
  children
}: {
  isVisible: boolean;
  children: JSX.Element[];
}) {
  if (isVisible) {
    return (
      <div className="flex justify-start cell constraints">
        <label>Bornes</label>
        {children}
      </div>
    );
  }
  return null;
}
