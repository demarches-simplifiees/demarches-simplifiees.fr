import { suite, test, expect } from 'vitest';

import { show, hide, toggle } from './utils';

suite('@utils', () => {
  test('show', () => {
    const input = document.createElement('input');
    input.classList.add('hidden');

    show(input);
    expect(input.classList.contains('hidden')).toBeFalsy();
  });

  test('hide', () => {
    const input = document.createElement('input');

    hide(input);
    expect(input.classList.contains('hidden')).toBeTruthy();
  });

  test('toggle', () => {
    const input = document.createElement('input');

    toggle(input);
    expect(input.classList.contains('hidden')).toBeTruthy();
    toggle(input);
    expect(input.classList.contains('hidden')).toBeFalsy();
  });
});
