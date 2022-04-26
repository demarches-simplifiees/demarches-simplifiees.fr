import React from 'react';

import type { Handler } from '../types';

export function TypeDeChampDateOption({
  label,
  handler
}: {
  label: string;
  handler: Handler<HTMLInputElement>;
}) {
  return (
    <div className="constraints">
      <label htmlFor={handler.id}>
        {label}
        <input
          type="date"
          id={handler.id}
          value={handler.value}
          name={handler.name}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </label>
    </div>
  );
}
