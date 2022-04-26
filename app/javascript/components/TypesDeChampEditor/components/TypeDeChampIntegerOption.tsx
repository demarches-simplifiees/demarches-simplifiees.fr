import React from 'react';
import PropTypes from 'prop-types';
import { Handler } from '~/components/TypesDeChampEditor/types';

export function TypeDeChampIntegerOption({
  label,
  handler
}: {
  label: string;
  handler: Handler<HTMLInputElement>;
}) {
  return (
    <label htmlFor={handler.id}>
      {label}
      <input
        type="number"
        id={handler.id}
        value={handler.value}
        name={handler.name}
        onChange={handler.onChange}
        className="small-margin small"
      />
    </label>
  );
}
