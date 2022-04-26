import React from 'react';
import PropTypes from 'prop-types';
import { Handler } from '~/components/TypesDeChampEditor/types';

export function TypeDeChampLevelOption({
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
        value={handler.value ? handler.value : '1'}
        name={handler.name}
        onChange={handler.onChange}
        className="small-margin small"
        min="1"
        max="3"
      />
    </label>
  );
}
