import React from 'react';

import type { Handler } from '../types';

export function TypeDeChampCarteOption({
  label,
  handler
}: {
  label: string;
  handler: Handler<HTMLInputElement>;
}) {
  return (
    <label htmlFor={handler.id}>
      <input
        type="checkbox"
        id={handler.id}
        name={handler.name}
        checked={!!handler.value}
        onChange={handler.onChange}
        className="small-margin small"
      />
      {label}
    </label>
  );
}
