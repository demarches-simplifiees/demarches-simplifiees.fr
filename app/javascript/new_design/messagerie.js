import { scrollTo, scrollToBottom } from '@utils';

export function scrollMessagerie() {
  const ul = document.querySelector('.messagerie ul');

  if (ul) {
    const elementToScroll = document.querySelector('.date.highlighted');

    if (elementToScroll) {
      scrollTo(ul, elementToScroll);
    } else {
      scrollToBottom(ul);
    }
  }
}

addEventListener('ds:page:update', scrollMessagerie);
