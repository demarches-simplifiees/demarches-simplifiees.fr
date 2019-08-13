import { delegate } from '@utils';

function updateReadMoreVisibility() {
  const descBody = document.querySelector('.procedure-description-body');
  if (descBody) {
    // If the description text overflows, display a "Read more" button.
    const isOverflowing = descBody.scrollHeight > descBody.clientHeight;
    descBody.classList.toggle('read-more-enabled', isOverflowing);
  }
}

function expandProcedureDescription() {
  const descBody = document.querySelector('.procedure-description-body');
  descBody.classList.remove('read-more-collapsed');
}

addEventListener('ds:page:update', updateReadMoreVisibility);
addEventListener('resize', updateReadMoreVisibility);

delegate('click', '.read-more-button', expandProcedureDescription);
