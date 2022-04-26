import React from 'react';

import type { Handler } from '../types';

export function LibelleInput({
  isVisible,
  handler
}: {
  isVisible: boolean;
  handler: Handler<HTMLInputElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell libelle">
        <label htmlFor={handler.id}>Libellé</label>
        <input
          type="text"
          id={handler.id}
          name={handler.name}
          value={handler.value}
          onChange={handler.onChange}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}
