import { delegate, fire, debounce } from '@utils';

const inputHandlers = new Map();

addEventListener('ds:page:update', () => {
  const inputs = document.querySelectorAll('.areas input[data-geo-area]');

  for (const input of inputs) {
    input.addEventListener('focus', (event) => {
      const id = parseInt(event.target.dataset.geoArea);
      fire(document, 'map:feature:focus', { id });
    });
  }
});

delegate('click', '.areas a[data-geo-area]', (event) => {
  event.preventDefault();
  const id = parseInt(event.target.dataset.geoArea);
  fire(document, 'map:feature:focus', { id });
});

delegate('input', '.areas input[data-geo-area]', (event) => {
  const id = parseInt(event.target.dataset.geoArea);

  let handler = inputHandlers.get(id);
  if (!handler) {
    handler = debounce(() => {
      const input = document.querySelector(`input[data-geo-area="${id}"]`);
      if (input) {
        fire(document, 'map:feature:update', {
          id,
          properties: { description: input.value.trim() }
        });
      }
    }, 200);
    inputHandlers.set(id, handler);
  }

  handler();
});
