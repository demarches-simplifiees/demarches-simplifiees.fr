import React from 'react';
import { Handler } from '~/components/TypesDeChampEditor/types';

export function TypeDeChampEmailList({
  isVisible,
  handler
}: {
  isVisible: boolean;
  handler: Handler<HTMLTextAreaElement>;
}) {
  if (isVisible) {
    return (
      <div className="cell">
        <label className="cell" htmlFor={handler.id}>
          Mails des personnes accréditées
        </label>
        <div className="flex justify-start">
          <div className="cell">
            <textarea
              id={handler.id}
              name={handler.name}
              value={handler.value}
              onChange={handler.onChange}
              rows={3}
              cols={40}
              placeholder="Ecrire un email par ligne"
              className="small-margin small"
            />
          </div>
          <div className="cell">
            <p>Ecrire un email d&apos;instructeur par ligne.</p>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
