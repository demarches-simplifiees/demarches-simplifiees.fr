import invariant from 'tiny-invariant';
import { isElement, dispatch, isInputElement } from '@coldwired/utils';
import { dispatchAction } from '@coldwired/actions';
import { createPopper, Instance as Popper } from '@popperjs/core';

import { Combobox, State, Action, Option, Hint } from './combobox';

const ctrlBindings = !!navigator.userAgent.match(/Macintosh/);

export type ComboboxUIOptions = {
  input: HTMLInputElement;
  valueInput: HTMLInputElement;
  list: HTMLUListElement;
  item: HTMLTemplateElement;
  allowsCustomValue?: boolean;
  hint?: HTMLElement;
  getHintText?: (hint: Hint) => string;
};

export class ComboboxUI implements EventListenerObject {
  #combobox?: Combobox;
  #popper?: Popper;
  #interactingWithList = false;
  #mouseOverList = false;
  #isComposing = false;

  #input: HTMLInputElement;
  #valueInput: HTMLInputElement;
  #list: HTMLUListElement;
  #item: HTMLTemplateElement;
  #hint?: HTMLElement;

  #getHintText = defaultGetHintText;
  #allowsCustomValue: boolean;

  constructor({
    input,
    valueInput,
    list,
    item,
    hint,
    getHintText,
    allowsCustomValue
  }: ComboboxUIOptions) {
    this.#input = input;
    this.#valueInput = valueInput;
    this.#list = list;
    this.#item = item;
    this.#hint = hint;
    this.#getHintText = getHintText ?? defaultGetHintText;
    this.#allowsCustomValue = allowsCustomValue ?? false;
  }

  init() {
    const selectedValue = this.#list.dataset.selected;
    const options = JSON.parse(this.#list.dataset.options ?? '[]') as Option[];
    this.#list.removeAttribute('data-options');
    this.#list.removeAttribute('data-selected');
    const selected =
      options.find(({ value }) => value == selectedValue) ?? null;

    this.#combobox = new Combobox({
      options,
      selected,
      allowsCustomValue: this.#allowsCustomValue,
      value: this.#input.value,
      render: (state) => this.render(state)
    });
    this.#combobox.init();

    this.#input.addEventListener('blur', this);
    this.#input.addEventListener('focus', this);
    this.#input.addEventListener('click', this);
    this.#input.addEventListener('input', this);
    this.#input.addEventListener('keydown', this);

    this.#list.addEventListener('mousedown', this);
    this.#list.addEventListener('mouseenter', this);
    this.#list.addEventListener('mouseleave', this);

    document.body.addEventListener('mouseup', this);
  }

  destroy() {
    this.#combobox?.destroy();
    this.#popper?.destroy();

    this.#input.removeEventListener('blur', this);
    this.#input.removeEventListener('focus', this);
    this.#input.removeEventListener('click', this);
    this.#input.removeEventListener('input', this);
    this.#input.removeEventListener('keydown', this);

    this.#list.removeEventListener('mousedown', this);
    this.#list.removeEventListener('mouseenter', this);
    this.#list.removeEventListener('mouseleave', this);

    document.body.removeEventListener('mouseup', this);
  }

  handleEvent(event: Event) {
    switch (event.type) {
      case 'input':
        this.onInputChange(event as InputEvent);
        break;
      case 'blur':
        this.onInputBlur();
        break;
      case 'focus':
        this.onInputFocus();
        break;
      case 'click':
        if (event.target == this.#input) {
          this.onInputClick(event as MouseEvent);
        } else {
          this.onListClick(event as MouseEvent);
        }
        break;
      case 'keydown':
        this.onKeydown(event as KeyboardEvent);
        break;
      case 'mousedown':
        this.onListMouseDown();
        break;
      case 'mouseenter':
        this.onListMouseEnter();
        break;
      case 'mouseleave':
        this.onListMouseLeave();
        break;
      case 'mouseup':
        this.onBodyMouseUp(event);
        break;
      case 'compositionstart':
      case 'compositionend':
        this.#isComposing = event.type == 'compositionstart';
        break;
    }
  }

  private get combobox() {
    invariant(this.#combobox, 'ComboboxUI requires a Combobox instance');
    return this.#combobox;
  }

  private render(state: State) {
    console.debug('combobox render', state);
    switch (state.action) {
      case Action.Select:
      case Action.Clear:
        this.renderSelect(state);
        break;
    }
    this.renderList(state);
    this.renderOptionList(state);
    this.renderValue(state);
    this.renderHintForScreenReader(state.hint);
  }

  private renderList(state: State): void {
    if (state.open) {
      if (!this.#list.hidden) return;
      this.#list.hidden = false;
      this.#list.classList.remove('hidden');
      this.#list.addEventListener('click', this);

      this.#input.setAttribute('aria-expanded', 'true');

      this.#input.addEventListener('compositionstart', this);
      this.#input.addEventListener('compositionend', this);

      this.#popper = createPopper(this.#input, this.#list, {
        placement: 'bottom-start'
      });
    } else {
      if (this.#list.hidden) return;
      this.#list.hidden = true;
      this.#list.classList.add('hidden');
      this.#list.removeEventListener('click', this);

      this.#input.setAttribute('aria-expanded', 'false');
      this.#input.removeEventListener('compositionstart', this);
      this.#input.removeEventListener('compositionend', this);

      this.#popper?.destroy();
      this.#interactingWithList = false;
    }
  }

  private renderValue(state: State): void {
    if (this.#input.value != state.inputValue) {
      this.#input.value = state.inputValue;
    }
    this.dispatchChange(() => {
      if (this.#valueInput.value != state.inputValue) {
        if (state.allowsCustomValue || !state.inputValue) {
          this.#valueInput.value = state.inputValue;
        }
      }
    });
  }

  private renderSelect(state: State): void {
    this.dispatchChange(() => {
      this.#valueInput.value = state.selection?.value ?? '';
      this.#input.value = state.selection?.label ?? '';
    });
  }

  private renderOptionList(state: State): void {
    const html = state.options
      .map(({ label, value }) => {
        const fragment = this.#item.content.cloneNode(true) as DocumentFragment;
        const item = fragment.querySelector('li');
        if (item) {
          item.id = optionId(value);
          item.setAttribute('data-turbo-force', 'server');
          if (state.focused?.value == value) {
            item.setAttribute('aria-selected', 'true');
          } else {
            item.removeAttribute('aria-selected');
          }
          item.setAttribute('data-value', value);
          item.querySelector('slot[name="label"]')?.replaceWith(label);
          return item.outerHTML;
        }
        return '';
      })
      .join('');

    dispatchAction({ targets: this.#list, action: 'update', fragment: html });

    if (state.focused) {
      const id = optionId(state.focused.value);
      const item = this.#list.querySelector<HTMLElement>(`#${id}`);
      this.#input.setAttribute('aria-activedescendant', id);
      if (item) {
        scrollTo(this.#list, item);
      }
    } else {
      this.#input.removeAttribute('aria-activedescendant');
    }
  }

  private renderHintForScreenReader(hint: Hint | null): void {
    if (this.#hint) {
      if (hint) {
        this.#hint.textContent = this.#getHintText(hint);
      } else {
        this.#hint.textContent = '';
      }
    }
  }

  private dispatchChange(cb: () => void): void {
    const value = this.#valueInput.value;
    cb();
    if (value != this.#valueInput.value) {
      console.debug('combobox change', this.#valueInput.value);
      dispatch('change', { target: this.#valueInput });
    }
  }

  private onKeydown(event: KeyboardEvent): void {
    if (event.shiftKey || event.metaKey || event.altKey) return;
    if (!ctrlBindings && event.ctrlKey) return;
    if (this.#isComposing) return;

    if (this.combobox.keyboard(event.key)) {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  private onInputClick(event: MouseEvent): void {
    const rect = this.#input.getBoundingClientRect();
    const clickOnArrow =
      event.clientX >= rect.right - 40 &&
      event.clientX <= rect.right &&
      event.clientY >= rect.top &&
      event.clientY <= rect.bottom;

    if (clickOnArrow) {
      this.combobox.toggle();
    }
  }

  private onListClick(event: MouseEvent): void {
    if (isElement(event.target)) {
      const element = event.target.closest<HTMLElement>('[role="option"]');
      if (element) {
        const value = element.getAttribute('data-value')?.trim();
        if (value) {
          this.combobox.select(value);
        }
      }
    }
  }

  private onInputFocus(): void {
    this.combobox.focus();
  }

  private onInputBlur(): void {
    if (!this.#interactingWithList) {
      this.combobox.close();
    }
  }

  private onInputChange(event: InputEvent): void {
    if (isInputElement(event.target)) {
      this.combobox.input(event.target.value);
    }
  }

  private onListMouseDown(): void {
    this.#interactingWithList = true;
  }

  private onBodyMouseUp(event: Event): void {
    if (
      this.#interactingWithList &&
      !this.#mouseOverList &&
      isElement(event.target) &&
      event.target != this.#list &&
      !this.#list.contains(event.target)
    ) {
      this.combobox.close();
    }
  }

  private onListMouseEnter(): void {
    this.#mouseOverList = true;
  }

  private onListMouseLeave(): void {
    this.#mouseOverList = false;
  }
}

function scrollTo(container: HTMLElement, target: HTMLElement): void {
  if (!inViewport(container, target)) {
    container.scrollTop = target.offsetTop;
  }
}

function inViewport(container: HTMLElement, element: HTMLElement): boolean {
  const scrollTop = container.scrollTop;
  const containerBottom = scrollTop + container.clientHeight;
  const top = element.offsetTop;
  const bottom = top + element.clientHeight;
  return top >= scrollTop && bottom <= containerBottom;
}

function optionId(value: string) {
  return `option-${value.replace(/\s/g, '-')}`;
}

function defaultGetHintText(hint: Hint): string {
  switch (hint.type) {
    case 'results':
      if (hint.label) {
        return `${hint.count} results. ${hint.label} is the top result: press Enter to activate.`;
      }
      return `${hint.count} results.`;
    case 'empty':
      return 'No results.';
    case 'selected':
      return `${hint.label} selected.`;
  }
}
