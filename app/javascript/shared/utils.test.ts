import { suite, test, expect } from 'vitest';

import {
  show,
  hide,
  toggle,
  toggleExpandIcon,
  isSelectElement,
  isTextInputElement,
  isCheckboxOrRadioInputElement
} from './utils';

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

  test('toggleExpandIcon', () => {
    const icon = document.createElement('icon');
    icon.classList.add('fr-icon-add-line');

    toggleExpandIcon(icon);
    console.log(icon.outerHTML);
    expect(icon.classList.contains('fr-icon-subtract-line')).toBeTruthy();
    expect(icon.classList.contains('fr-icon-add-line')).toBeFalsy();
    toggleExpandIcon(icon);
    expect(icon.classList.contains('fr-icon-add-line')).toBeTruthy();
    expect(icon.classList.contains('fr-icon-subtract-line')).toBeFalsy();
    console.log(icon.outerHTML);
  });

  test('isSelectElement', () => {
    const select = document.createElement('select');
    const input = document.createElement('input');
    const textarea = document.createElement('textarea');

    expect(isSelectElement(select)).toBeTruthy();
    expect(isSelectElement(input)).toBeFalsy();
    expect(isSelectElement(textarea)).toBeFalsy();

    input.type = 'text';
    expect(isSelectElement(input)).toBeFalsy();

    input.type = 'email';
    expect(isSelectElement(input)).toBeFalsy();

    input.type = 'checkbox';
    expect(isSelectElement(input)).toBeFalsy();

    input.type = 'radio';
    expect(isSelectElement(input)).toBeFalsy();

    input.type = 'file';
    expect(isSelectElement(input)).toBeFalsy();
  });

  test('isTextInputElement', () => {
    const select = document.createElement('select');
    const input = document.createElement('input');
    const textarea = document.createElement('textarea');

    expect(isTextInputElement(select)).toBeFalsy();
    expect(isTextInputElement(input)).toBeTruthy();
    expect(isTextInputElement(textarea)).toBeTruthy();

    input.type = 'text';
    expect(isTextInputElement(input)).toBeTruthy();

    input.type = 'email';
    expect(isTextInputElement(input)).toBeTruthy();

    input.type = 'checkbox';
    expect(isTextInputElement(input)).toBeFalsy();

    input.type = 'radio';
    expect(isTextInputElement(input)).toBeFalsy();

    input.type = 'file';
    expect(isTextInputElement(input)).toBeFalsy();
  });

  test('isCheckboxOrRadioInputElement', () => {
    const select = document.createElement('select');
    const input = document.createElement('input');
    const textarea = document.createElement('textarea');

    expect(isCheckboxOrRadioInputElement(select)).toBeFalsy();
    expect(isCheckboxOrRadioInputElement(input)).toBeFalsy();
    expect(isCheckboxOrRadioInputElement(textarea)).toBeFalsy();

    input.type = 'text';
    expect(isCheckboxOrRadioInputElement(input)).toBeFalsy();

    input.type = 'email';
    expect(isCheckboxOrRadioInputElement(input)).toBeFalsy();

    input.type = 'checkbox';
    expect(isCheckboxOrRadioInputElement(input)).toBeTruthy();

    input.type = 'radio';
    expect(isCheckboxOrRadioInputElement(input)).toBeTruthy();

    input.type = 'file';
    expect(isCheckboxOrRadioInputElement(input)).toBeFalsy();
  });
});
