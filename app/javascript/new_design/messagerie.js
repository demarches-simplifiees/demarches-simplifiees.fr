import { scrollToElement, scrollToBottom } from '@utils';

function scrollMessagerie() {
  const ul = document.querySelector('.messagerie ul');

  if (ul) {
    const elementToScroll = document.querySelector('.date.highlighted');

    if (elementToScroll) {
      scrollToElement(ul, elementToScroll);
    } else {
      scrollToBottom(ul);
    }
  }
}

function saveMessageContent() {
  const commentaireForms = Array.from(
    document.querySelectorAll('form[data-persisted-content-id]')
  );

  if (commentaireForms.length) {
    const commentaireInputs = Array.from(
      document.querySelectorAll('.persisted-input')
    );

    const persistedContentIds = commentaireForms.map(
      (form) => form.dataset.persistedContentId
    );

    const keys = persistedContentIds.map((key) => `persisted-value-${key}`);

    const object = commentaireInputs.map((input, index) => {
      return {
        input: input,
        form: commentaireForms[index],
        key: keys[index]
      };
    });

    for (const el of object) {
      if (localStorage.getItem(el.key)) {
        el.input.value = localStorage.getItem(el.key);
      }

      el.input.addEventListener('change', (event) => {
        localStorage.setItem(el.key, event.target.value);
      });

      el.form.addEventListener('submit', () => {
        localStorage.removeItem(el.key);
      });
    }
  }
}

addEventListener('ds:page:update', scrollMessagerie);
addEventListener('ds:page:update', saveMessageContent);
