import { matchSorter } from 'match-sorter';

export enum Action {
  Init = 'init',
  Open = 'open',
  Close = 'close',
  Navigate = 'navigate',
  Select = 'select',
  Clear = 'clear',
  Update = 'update'
}
export type Option = { value: string; label: string; data?: unknown };
export type Hint =
  | {
      type: 'results';
      label: string | null;
      count: number;
    }
  | { type: 'empty' }
  | { type: 'selected'; label: string };
export type State = {
  action: Action;
  open: boolean;
  inputValue: string;
  focused: Option | null;
  selection: Option | null;
  options: Option[];
  allowsCustomValue: boolean;
  hint: Hint | null;
  loading: boolean | null;
};

export type Fetcher = (
  term: string,
  options?: { signal: AbortSignal }
) => Promise<Option[]>;

export class Combobox {
  #allowsCustomValue = false;
  #limit?: number;
  #open = false;
  #inputValue = '';
  #selectedOption: Option | null = null;
  #focusedOption: Option | null = null;
  #options: Option[] = [];
  #visibleOptions: Option[] = [];
  #render: (state: State) => void;
  #fetcher: Fetcher | null;
  #abortController?: AbortController | null;

  constructor({
    options,
    selected,
    allowsCustomValue,
    limit,
    render
  }: {
    options: Option[] | Fetcher;
    selected: Option | null;
    allowsCustomValue?: boolean;
    limit?: number;
    render: (state: State) => void;
  }) {
    this.#allowsCustomValue = allowsCustomValue ?? false;
    this.#limit = limit;
    this.#options = Array.isArray(options) ? options : [];
    this.#fetcher = Array.isArray(options) ? null : options;
    this.#selectedOption = selected;
    if (this.#selectedOption) {
      this.#inputValue = this.#selectedOption.label;
    }
    this.#render = render;
  }

  init(): void {
    this.#visibleOptions = this._filterOptions();
    this._render(Action.Init);
  }

  destroy(): void {
    this.#render = () => null;
  }

  navigate(indexDiff: -1 | 1 = 1): void {
    const focusIndex = this._focusedOptionIndex;
    const lastIndex = this.#visibleOptions.length - 1;

    let indexOfItem = indexDiff == 1 ? 0 : lastIndex;
    if (focusIndex == lastIndex && indexDiff == 1) {
      indexOfItem = 0;
    } else if (focusIndex == 0 && indexDiff == -1) {
      indexOfItem = lastIndex;
    } else if (focusIndex == -1) {
      indexOfItem = 0;
    } else {
      indexOfItem = focusIndex + indexDiff;
    }

    this.#focusedOption = this.#visibleOptions.at(indexOfItem) ?? null;

    this._render(Action.Navigate);
  }

  select(value?: string): boolean {
    const maybeValue = this._nextSelectValue(value);
    if (!maybeValue) {
      this.close();
      return false;
    }

    const option = this.#visibleOptions.find(
      (option) => option.value.trim() == maybeValue.trim()
    );
    if (!option) return false;

    this.#selectedOption = option;
    this.#focusedOption = null;
    this.#inputValue = option.label;
    this.#open = false;
    this.#visibleOptions = this._filterOptions();

    this._render(Action.Select);
    return true;
  }

  async input(value: string) {
    if (this.#inputValue == value) return;

    this.#inputValue = value;

    if (this.#fetcher) {
      this.#abortController?.abort();
      this.#abortController = new AbortController();
      this._render(Action.Update);
      this.#options = await this.#fetcher(value, {
        signal: this.#abortController.signal
      }).catch(() => []);
      this.#abortController = null;
      this._render(Action.Update);

      this.#selectedOption = null;
    } else {
      this.#selectedOption = null;
    }

    this.#visibleOptions = this._filterOptions();

    if (this.#visibleOptions.length > 0) {
      if (!this.#open) {
        this.open();
      } else {
        this._render(Action.Update);
      }
    } else if (this.#allowsCustomValue) {
      this.#open = false;
      this.#focusedOption = null;
      this._render(Action.Close);
    } else {
      this._render(Action.Update);
    }
  }

  keyboard(key: string) {
    switch (key) {
      case 'Enter':
      case 'Tab':
        return this.select();
      case 'Escape':
        this.close();
        return true;
      case 'ArrowDown':
        if (this.#open) {
          this.navigate(1);
        } else {
          this.open();
        }
        return true;
      case 'ArrowUp':
        if (this.#open) {
          this.navigate(-1);
        } else {
          this.open();
        }
        return true;
    }
  }

  clear() {
    if (!this.#inputValue && !this.#selectedOption) return;
    this.#inputValue = '';
    this.#selectedOption = this.#focusedOption = null;
    this.#visibleOptions = this.#options;
    this.#visibleOptions = this._filterOptions();
    this._render(Action.Clear);
  }

  open() {
    if (this.#open || this.#visibleOptions.length == 0) return;
    this.#open = true;
    this.#focusedOption = this.#selectedOption;
    this._render(Action.Open);
  }

  close() {
    this.#open = false;
    this.#focusedOption = null;
    if (!this.#allowsCustomValue && !this.#selectedOption) {
      this.#inputValue = '';
    }
    this.#visibleOptions = this._filterOptions();
    this._render(Action.Close);
  }

  focus() {
    if (this.#open) return;
    if (this.#selectedOption) return;

    this.open();
  }

  toggle() {
    this.#open ? this.close() : this.open();
  }

  private _nextSelectValue(value?: string): string | false {
    if (value) {
      return value;
    }
    if (this.#focusedOption && this._focusedOptionIndex != -1) {
      return this.#focusedOption.value;
    }
    if (this.#allowsCustomValue) {
      return false;
    }
    if (this.#inputValue.length > 0 && !this.#selectedOption) {
      return this.#visibleOptions.at(0)?.value ?? false;
    }
    return false;
  }

  private _filterOptions(): Option[] {
    const emptyOrSelected =
      !this.#inputValue || this.#inputValue == this.#selectedOption?.value;
    const options = emptyOrSelected
      ? this.#options
      : matchSorter(this.#options, this.#inputValue, {
          keys: ['label']
        });

    if (this.#limit) {
      return options.slice(0, this.#limit);
    }
    return options;
  }

  private get _focusedOptionIndex(): number {
    if (this.#focusedOption) {
      return this.#visibleOptions.indexOf(this.#focusedOption);
    }
    return -1;
  }

  private _render(action: Action): void {
    this.#render(this._getState(action));
  }

  private _getState(action: Action): State {
    const state = {
      action,
      open: this.#open,
      options: this.#visibleOptions,
      inputValue: this.#inputValue,
      focused: this.#focusedOption,
      selection: this.#selectedOption,
      allowsCustomValue: this.#allowsCustomValue,
      hint: null,
      loading: this.#abortController ? true : this.#fetcher ? false : null
    };

    return { ...state, hint: this._getFeedback(state) };
  }

  private _getFeedback(state: State): Hint | null {
    const count = state.options.length;
    if (state.action == Action.Open || state.action == Action.Update) {
      if (!state.selection) {
        const defaultOption = state.options.at(0);
        if (defaultOption) {
          return { type: 'results', label: defaultOption.label, count };
        } else if (count > 0) {
          return { type: 'results', label: null, count };
        }
        return { type: 'empty' };
      }
    } else if (state.action == Action.Select && state.selection) {
      return { type: 'selected', label: state.selection.label };
    }
    return null;
  }
}
