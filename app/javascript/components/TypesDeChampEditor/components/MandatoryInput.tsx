import React from 'react';

import type { Handler } from '../types';

export function MandatoryInput({
  isVisible,
  handler
}: {
  isVisible: boolean;
  handler: Handler<HTMLInputElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Obligatoire</label>
        <input
          type="checkbox"
          id={handler.id}
          name={handler.name}
          checked={!!handler.value}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}
