import React from 'react';
import { Handler } from '~/components/TypesDeChampEditor/types';

export function TypeDeChampTeFenuaOption({
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
