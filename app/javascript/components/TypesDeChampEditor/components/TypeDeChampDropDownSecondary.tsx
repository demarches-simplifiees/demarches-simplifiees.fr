import React from 'react';

import type { Handler } from '../types';

export function TypeDeChampDropDownSecondary({
  isVisible,
  libelleHandler,
  descriptionHandler
}: {
  isVisible: boolean;
  libelleHandler: Handler<HTMLInputElement>;
  descriptionHandler: Handler<HTMLTextAreaElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={libelleHandler.id}>Libellé secondaire</label>
        <input
          type="text"
          id={libelleHandler.id}
          name={libelleHandler.name}
          value={libelleHandler.value ?? ''}
          onChange={libelleHandler.onChange}
          className="small-margin small"
        />
        <label htmlFor={descriptionHandler.id}>Description secondaire</label>
        <textarea
          id={descriptionHandler.id}
          name={descriptionHandler.name}
          value={descriptionHandler.value ?? ''}
          onChange={descriptionHandler.onChange}
          rows={3}
          cols={40}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}
