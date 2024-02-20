import invariant from 'tiny-invariant';
import { isElement, dispatch, isInputElement } from '@coldwired/utils';
import { dispatchAction } from '@coldwired/actions';
import { createPopper, Instance as Popper } from '@popperjs/core';

import {
  Combobox,
  Action,
  type State,
  type Option,
  type Hint,
  type Fetcher
} from './combobox';

const ctrlBindings = !!navigator.userAgent.match(/Macintosh/);

export type ComboboxUIOptions = {
  input: HTMLInputElement;
  selectedValueInput: HTMLInputElement;
  list: HTMLUListElement;
  item: HTMLTemplateElement;
  valueSlots?: HTMLInputElement[] | NodeListOf<HTMLInputElement>;
  allowsCustomValue?: boolean;
  limit?: number;
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
  #selectedValueInput: HTMLInputElement;
  #valueSlots: HTMLInputElement[];
  #list: HTMLUListElement;
  #item: HTMLTemplateElement;
  #hint?: HTMLElement;

  #getHintText = defaultGetHintText;
  #allowsCustomValue: boolean;
  #limit?: number;

  #selectedData: Option['data'] = null;

  constructor({
    input,
    selectedValueInput,
    valueSlots,
    list,
    item,
    hint,
    getHintText,
    allowsCustomValue,
    limit
  }: ComboboxUIOptions) {
    this.#input = input;
    this.#selectedValueInput = selectedValueInput;
    this.#valueSlots = valueSlots ? Array.from(valueSlots) : [];
    this.#list = list;
    this.#item = item;
    this.#hint = hint;
    this.#getHintText = getHintText ?? defaultGetHintText;
    this.#allowsCustomValue = allowsCustomValue ?? false;
    this.#limit = limit;
  }

  init() {
    if (this.#list.dataset.url) {
      const fetcher = createFetcher(this.#list.dataset.url);

      this.#list.removeAttribute('data-url');

      const selected: Option | null = this.#input.value
        ? { label: this.#input.value, value: this.#selectedValueInput.value }
        : null;
      this.#combobox = new Combobox({
        options: fetcher,
        selected,
        allowsCustomValue: this.#allowsCustomValue,
        limit: this.#limit,
        render: (state) => this.render(state)
      });
    } else {
      const selectedValue = this.#selectedValueInput.value;
      const options = JSON.parse(
        this.#list.dataset.options ?? '[]'
      ) as Option[];
      const selected =
        options.find(({ value }) => value == selectedValue) ?? null;

      this.#list.removeAttribute('data-options');
      this.#list.removeAttribute('data-selected');

      this.#combobox = new Combobox({
        options,
        selected,
        allowsCustomValue: this.#allowsCustomValue,
        limit: this.#limit,
        render: (state) => this.render(state)
      });
    }

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
      if (this.#selectedValueInput.value != state.inputValue) {
        if (state.allowsCustomValue || !state.inputValue) {
          this.#selectedValueInput.value = state.inputValue;
        }
      }
      return state.selection?.data;
    });
  }

  private renderSelect(state: State): void {
    this.dispatchChange(() => {
      this.#selectedValueInput.value = state.selection?.value ?? '';
      this.#input.value = state.selection?.label ?? '';
      return state.selection?.data;
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

  private dispatchChange(cb: () => Option['data']): void {
    const value = this.#selectedValueInput.value;
    const data = cb();
    if (value != this.#selectedValueInput.value || data != this.#selectedData) {
      this.#selectedData = data;
      for (const input of this.#valueSlots) {
        switch (input.dataset.valueSlot) {
          case 'value':
            input.value = this.#selectedValueInput.value;
            break;
          case 'label':
            input.value = this.#input.value;
            break;
          case 'data:string':
            input.value = data ? String(data) : '';
            break;
          case 'data':
            input.value = data ? JSON.stringify(data) : '';
            break;
        }
      }
      console.debug('combobox change', this.#selectedValueInput.value);
      dispatch('change', {
        target: this.#selectedValueInput,
        detail: data ? { data } : undefined
      });
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
  return `option-${value
    .toLowerCase()
    // Replace spaces and special characters with underscores
    .replace(/[^a-z0-9]/g, '_')
    // Remove non-alphanumeric characters at start and end
    .replace(/^[^a-z]+|[^\w]$/g, '')}`;
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

function createFetcher(source: string, param = 'q'): Fetcher {
  const url = new URL(source, location.href);

  const fetcher: Fetcher = (term: string, options) => {
    url.searchParams.set(param, term);
    return fetch(url.toString(), {
      headers: { accept: 'application/json' },
      signal: options?.signal
    }).then<Option[]>((response) => {
      if (response.ok) {
        return response.json();
      }
      return [];
    });
  };

  return async (term: string, options) => {
    await wait(500, options?.signal);
    return fetcher(term, options);
  };
}

function wait(ms: number, signal?: AbortSignal) {
  return new Promise((resolve, reject) => {
    const abort = () => reject(new DOMException('Aborted', 'AbortError'));
    if (signal?.aborted) {
      abort();
    } else {
      signal?.addEventListener('abort', abort);
      setTimeout(resolve, ms);
    }
  });
}
