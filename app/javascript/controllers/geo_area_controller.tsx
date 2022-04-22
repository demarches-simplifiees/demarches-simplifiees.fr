import { Controller } from '@hotwired/stimulus';
import { debounce } from '@utils';

type Detail = Record<string, unknown>;

export class GeoAreaController extends Controller {
  static values = {
    id: String,
    description: String
  };
  static targets = ['description'];

  declare readonly idValue: string;
  declare readonly descriptionTarget: HTMLInputElement;

  onFocus() {
    this.globalDispatch('map:feature:focus', { id: this.idValue });
  }

  onClick(event: MouseEvent) {
    event.preventDefault();
    this.globalDispatch('map:feature:focus', { id: this.idValue });
  }

  onInput() {
    this.debounce(this.updateDescription, 200);
  }

  private updateDescription(): void {
    this.globalDispatch('map:feature:update', {
      id: this.idValue,
      properties: { description: this.descriptionTarget.value.trim() }
    });
  }

  #debounced = new Map<() => void, () => void>();
  private debounce(fn: () => void, interval: number): void {
    let debounced = this.#debounced.get(fn);
    if (!debounced) {
      debounced = debounce(fn.bind(this), interval);
      this.#debounced.set(fn, debounced);
    }
    debounced();
  }

  private globalDispatch(type: string, detail: Detail): void {
    this.dispatch(type, {
      detail,
      prefix: '',
      target: document.documentElement
    });
  }
}
