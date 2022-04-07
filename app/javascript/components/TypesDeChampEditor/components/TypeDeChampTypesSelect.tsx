import React from 'react';

import type { Handler } from '../types';

export function TypeDeChampTypesSelect({
  handler,
  options
}: {
  handler: Handler<HTMLSelectElement>;
  options: [label: string, type: string][];
}) {
  return (
    <div className="cell">
      <select
        id={handler.id}
        name={handler.name}
        onChange={handler.onChange}
        value={handler.value}
        className="small-margin small inline"
      >
        {options.map(([label, key]) => (
          <option key={key} value={key}>
            {label}
          </option>
        ))}
      </select>
    </div>
  );
}
