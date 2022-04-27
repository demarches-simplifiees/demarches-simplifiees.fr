import React from 'react';

import type { Handler } from '../types';

export function TypeDeChampDropDownOther({
  isVisible,
  handler
}: {
  isVisible: boolean;
  handler: Handler<HTMLInputElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>
          <input
            type="checkbox"
            id={handler.id}
            name={handler.name}
            checked={!!handler.value}
            onChange={handler.onChange}
            className="small-margin small"
          />
          Proposer une option &apos;autre&apos; avec un texte libre
        </label>
      </div>
    );
  }
  return null;
}
