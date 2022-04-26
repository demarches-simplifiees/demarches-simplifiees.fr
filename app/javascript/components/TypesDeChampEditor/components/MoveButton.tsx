import React, { MouseEventHandler } from 'react';
import { ArrowDownIcon, ArrowUpIcon } from '@heroicons/react/solid';

export function MoveButton({
  isEnabled,
  icon,
  title,
  onClick
}: {
  isEnabled: boolean;
  icon: string;
  title: string;
  onClick: MouseEventHandler<HTMLButtonElement>;
}) {
  return (
    <button
      className="button small move"
      disabled={!isEnabled}
      title={title}
      onClick={onClick}
    >
      {icon == 'arrow-up' ? (
        <ArrowUpIcon className="icon-size" />
      ) : (
        <ArrowDownIcon className="icon-size" />
      )}
    </button>
  );
}
