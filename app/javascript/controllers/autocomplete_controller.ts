import { matchSorter } from 'match-sorter';
import { ActionEvent } from '@hotwired/stimulus';
import { show, hide } from '@utils';

import { ApplicationController } from './application_controller';

// Mostly inspired by https://www.24a11y.com/2019/select-your-poison/
export class AutocompleteController extends ApplicationController {
  #options: string[] = [];
  #filteredOptions: string[] = [];
  #ignoreBlur = false;
  #activeIndex = 0;
  #selectedValue = '';
  #open = false;

  static targets = ['combobox', 'input', 'listbox', 'option'];

  declare readonly comboboxTarget: HTMLDivElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly listboxTarget: HTMLUListElement;
  declare readonly optionTargets: HTMLLIElement[];

  connect() {
    this.#options = this.optionTargets.map(
      (element) => element.textContent as string
    );
    this.#filteredOptions = this.#options;
    this.inputTarget.value = this.#options[0];
  }

  onInput() {
    const curValue = this.inputTarget.value;
    this.filterOptions(curValue);

    // if active option is not in filtered options, set it to first filtered option
    if (this.#filteredOptions.indexOf(this.#options[this.#activeIndex]) < 0) {
      const firstFilteredIndex = this.#options.indexOf(
        this.#filteredOptions[0]
      );
      this.onOptionChange(firstFilteredIndex);
    }

    const menuState = this.#filteredOptions.length > 0;
    if (this.#open !== menuState) {
      this.updateMenuState(menuState, false);
    }
  }

  onInputKeyDown(event: KeyboardEvent) {
    const { key } = event;

    const max = this.#filteredOptions.length - 1;
    const activeFilteredIndex = this.#filteredOptions.indexOf(
      this.#options[this.#activeIndex]
    );

    const action = getActionFromKey(key, this.#open);

    switch (action) {
      case MenuActions.Next:
      case MenuActions.Last:
      case MenuActions.First:
      case MenuActions.Previous:
        event.preventDefault();
        return this.onOptionChange(
          this.getNextRealIndex(activeFilteredIndex, max, action)
        );
      case MenuActions.CloseSelect:
        event.preventDefault();
        this.selectOption(this.#activeIndex);
        return this.updateMenuState(false);
      case MenuActions.Close:
        event.preventDefault();
        this.onOptionChange(this.#options.indexOf(this.#selectedValue));
        this.selectOption(this.#options.indexOf(this.#selectedValue));
        this.filterOptions('');
        return this.updateMenuState(false);
      case MenuActions.Open:
        return this.updateMenuState(true);
    }
  }

  onInputClick() {
    this.updateMenuState(true);
  }

  onInputBlur() {
    if (this.#ignoreBlur) {
      this.#ignoreBlur = false;
      return;
    }

    if (this.#open) {
      this.selectOption(this.#activeIndex);
      this.updateMenuState(false, false);
    }
  }

  onOptionClick(event: ActionEvent) {
    const index = event.params.index as number;
    this.onOptionChange(index);
    this.selectOption(index);
    this.updateMenuState(false);
  }

  onOptionMouseDown() {
    this.#ignoreBlur = true;
  }

  private onOptionChange(index: number) {
    this.#activeIndex = index;
    this.inputTarget.setAttribute(
      'aria-activedescendant',
      this.optionId(index)
    );

    for (const optionEl of this.optionTargets) {
      optionEl.classList.remove('option-current');
    }
    this.optionTargets[index].classList.add('option-current');

    if (this.#open && isScrollable(this.listboxTarget)) {
      maintainScrollVisibility(this.optionTargets[index], this.listboxTarget);
    }
  }

  private selectOption(index: number) {
    const selected = this.#options[index];
    this.inputTarget.value = selected;
    this.#activeIndex = index;
    this.#selectedValue = selected;
    this.filterOptions(selected);

    for (const optionEl of this.optionTargets) {
      optionEl.setAttribute('aria-selected', 'false');
    }
    this.optionTargets[index].setAttribute('aria-selected', 'true');
  }

  private optionId(index: number) {
    return `${this.inputTarget.id}-option-${index}`;
  }

  private updateMenuState(open: boolean, callFocus = true) {
    this.#open = open;
    this.comboboxTarget.setAttribute('aria-expanded', `${open}`);
    this.element.classList.toggle('hidden', !open);
    callFocus && this.inputTarget.focus();
  }

  private getNextRealIndex(
    activeFilteredIndex: number,
    max: number,
    action: number
  ) {
    const nextFilteredIndex = getUpdatedIndex(activeFilteredIndex, max, action);
    return this.#options.indexOf(this.#filteredOptions[nextFilteredIndex]);
  }

  private filterOptions(value: string) {
    this.#filteredOptions = matchSorter(this.#options, value);

    for (const optionEl of this.optionTargets) {
      const value = optionEl.innerText;
      if (this.#filteredOptions.includes(value)) {
        show(optionEl);
      } else {
        hide(optionEl);
      }
    }
  }
}

const Keys = {
  Backspace: 'Backspace',
  Clear: 'Clear',
  Down: 'ArrowDown',
  End: 'End',
  Enter: 'Enter',
  Escape: 'Escape',
  Home: 'Home',
  Left: 'ArrowLeft',
  PageDown: 'PageDown',
  PageUp: 'PageUp',
  Right: 'ArrowRight',
  Space: ' ',
  Tab: 'Tab',
  Up: 'ArrowUp'
};

const MenuActions = {
  Close: 0,
  CloseSelect: 1,
  First: 2,
  Last: 3,
  Next: 4,
  Open: 5,
  Previous: 6,
  Select: 7,
  Space: 8,
  Type: 9
};

// return combobox action from key press
function getActionFromKey(key: string, menuOpen: boolean) {
  // handle opening when closed
  if (!menuOpen && key == Keys.Down) {
    return MenuActions.Open;
  }

  // handle keys when open
  if (key == Keys.Down) {
    return MenuActions.Next;
  } else if (key == Keys.Up) {
    return MenuActions.Previous;
  } else if (key == Keys.Home) {
    return MenuActions.First;
  } else if (key == Keys.End) {
    return MenuActions.Last;
  } else if (key == Keys.Escape) {
    return MenuActions.Close;
  } else if (key == Keys.Enter) {
    return MenuActions.CloseSelect;
  } else if (key == Keys.Backspace || key == Keys.Clear || key.length == 1) {
    return MenuActions.Type;
  }
}

// get updated option index
function getUpdatedIndex(current: number, max: number, action: number) {
  switch (action) {
    case MenuActions.First:
      return 0;
    case MenuActions.Last:
      return max;
    case MenuActions.Previous:
      return Math.max(0, current - 1);
    case MenuActions.Next:
      return Math.min(max, current + 1);
    default:
      return current;
  }
}

// check if an element is currently scrollable
function isScrollable(element: HTMLElement) {
  return element && element.clientHeight < element.scrollHeight;
}

// ensure given child element is within the parent's visible scroll area
function maintainScrollVisibility(
  activeElement: HTMLElement,
  scrollParent: HTMLElement
) {
  const { offsetHeight, offsetTop } = activeElement;
  const { offsetHeight: parentOffsetHeight, scrollTop } = scrollParent;

  const isAbove = offsetTop < scrollTop;
  const isBelow = offsetTop + offsetHeight > scrollTop + parentOffsetHeight;

  if (isAbove) {
    scrollParent.scrollTo(0, offsetTop);
  } else if (isBelow) {
    scrollParent.scrollTo(0, offsetTop - parentOffsetHeight + offsetHeight);
  }
}
