import { delegate, toggle } from '@utils';

// Unobtrusive Javascript for allowing an element to toggle
// the visibility of another element.
//
// Usage:
//   <button data-toggle-target="#target">Toggle</button>
//   <div id="target">Content</div>

const TOGGLE_SOURCE_SELECTOR = '[data-toggle-target]';

delegate('click', TOGGLE_SOURCE_SELECTOR, (evt) => {
  evt.preventDefault();

  const targetSelector = evt.target.dataset.toggleTarget;
  const targetElements = document.querySelectorAll(targetSelector);
  for (let target of targetElements) {
    toggle(target);
  }
});
