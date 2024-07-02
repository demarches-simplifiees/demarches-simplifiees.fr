import { createPortal } from 'react-dom';
import invariant from 'tiny-invariant';

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
  const element = document.getElementById('flash_messages');
  invariant(element, 'Flash messages root element not found');
  return createPortal(
    <div className="flash_message center">
      <div
        className={flashClassName(level, sticky, fixed)}
        role={roleName(level)}
      >
        {message}
      </div>
    </div>,
    element
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

function roleName(level: string) {
  return level == 'notice' ? 'status' : 'alert';
}
