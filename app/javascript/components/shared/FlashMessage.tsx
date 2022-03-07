import React from 'react';
import { createPortal } from 'react-dom';

export function FlashMessage({
  message,
  level,
  sticky,
  fixed
}: {
  message: string;
  level: string;
  sticky?: boolean;
  fixed?: boolean;
}) {
  return createPortal(
    <div className="flash_message center">
      <div className={flashClassName(level, sticky, fixed)}>{message}</div>
    </div>,
    document.getElementById('flash_messages')!
  );
}

function flashClassName(level: string, sticky = false, fixed = false) {
  const className =
    level == 'notice' ? ['alert', 'alert-success'] : ['alert', 'alert-danger'];

  if (sticky) {
    className.push('sticky');
  }
  if (fixed) {
    className.push('alert-fixed');
  }
  return className.join(' ');
}
