import Sortable from 'sortablejs';

import { ApplicationController } from './application_controller';

export class SortableController extends ApplicationController {
  declare readonly animationValue: number;
  declare readonly handleValue: string;
  declare readonly groupValue: string;

  #sortable?: Sortable;

  static values = {
    animation: Number,
    handle: String,
    group: String
  };

  connect() {
    this.#sortable = new Sortable(this.element as HTMLElement, {
      ...this.defaultOptions,
      ...this.options
    });
    this.onGlobal('sortable:sort', () => this.setEdgeClassNames());
  }

  disconnect() {
    this.#sortable?.destroy();
  }

  private onEnd({ item, newIndex }: { item: HTMLElement; newIndex?: number }) {
    if (newIndex == null) return;

    this.dispatch('end', {
      target: item,
      detail: { position: newIndex }
    });
    this.setEdgeClassNames();
  }

  setEdgeClassNames() {
    const items = this.element.children;
    for (const item of items) {
      item.classList.remove('first', 'last');
    }
    if (items.length > 1) {
      const first = items[0];
      const last = items[items.length - 1];
      first?.classList.add('first');
      last?.classList.add('last');
    }
  }

  get options(): Sortable.Options {
    return {
      animation: this.animationValue || this.defaultOptions.animation || 150,
      handle: this.handleValue || this.defaultOptions.handle || undefined,
      group: this.groupValue || this.defaultOptions.group || undefined,
      onEnd: (event) => this.onEnd(event)
    };
  }

  get defaultOptions(): Sortable.Options {
    return {
      fallbackOnBody: true,
      swapThreshold: 0.65
    };
  }
}
