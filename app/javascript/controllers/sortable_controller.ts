import { Controller } from '@hotwired/stimulus';
import Sortable from 'sortablejs';
import { httpRequest } from '@utils';

export class SortableController extends Controller {
  declare readonly animationValue: number;
  declare readonly resourceNameValue: string;
  declare readonly paramNameValue: string;
  declare readonly handleValue: string;

  #sortable?: Sortable;

  static values = {
    resourceName: String,
    paramName: {
      type: String,
      default: 'position'
    },
    animation: Number,
    handle: String
  };

  initialize() {
    this.end = this.end.bind(this);
  }

  connect() {
    this.#sortable = new Sortable(this.element as HTMLElement, {
      ...this.defaultOptions,
      ...this.options
    });
  }

  disconnect() {
    this.#sortable?.destroy();
    this.#sortable = undefined;
  }

  async end({ item, newIndex }: { item: HTMLElement; newIndex?: number }) {
    if (!item.dataset.sortableUpdateUrl || newIndex == null) return;

    const param = this.resourceNameValue
      ? `${this.resourceNameValue}[${this.paramNameValue}]`
      : this.paramNameValue;

    const data = new FormData();
    data.append(param, String(newIndex));

    await httpRequest(item.dataset.sortableUpdateUrl, {
      method: 'patch',
      body: data
    }).turbo();
  }

  get options(): Sortable.Options {
    return {
      animation: this.animationValue || this.defaultOptions.animation || 150,
      handle: this.handleValue || this.defaultOptions.handle || undefined,
      onEnd: this.end
    };
  }

  get defaultOptions(): Sortable.Options {
    return {};
  }
}
