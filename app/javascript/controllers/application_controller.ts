import { Controller } from '@hotwired/stimulus';
import { debounce } from '@utils';

export type Detail = Record<string, unknown>;

export class ApplicationController extends Controller {
  #debounced = new Map<() => void, () => void>();

  protected debounce(fn: () => void, interval: number): void {
    let debounced = this.#debounced.get(fn);
    if (!debounced) {
      debounced = debounce(fn.bind(this), interval);
      this.#debounced.set(fn, debounced);
    }
    debounced();
  }

  protected globalDispatch(type: string, detail: Detail): void {
    this.dispatch(type, {
      detail,
      prefix: '',
      target: document.documentElement
    });
  }
}
