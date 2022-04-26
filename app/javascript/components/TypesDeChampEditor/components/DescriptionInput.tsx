import React from 'react';

import type { Handler } from '../types';

export function DescriptionInput({
  isVisible,
  handler
}: {
  isVisible: boolean;
  handler: Handler<HTMLTextAreaElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Description</label>
        <textarea
          id={handler.id}
          name={handler.name}
          value={handler.value || ''}
          onChange={handler.onChange}
          rows={3}
          cols={40}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}
