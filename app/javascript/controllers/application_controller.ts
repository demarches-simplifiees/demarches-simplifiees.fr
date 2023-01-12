import { Controller } from '@hotwired/stimulus';
import debounce from 'debounce';

export type Detail = Record<string, unknown>;

export class ApplicationController extends Controller {
  #debounced = new Map<() => void, ReturnType<typeof debounce>>();

  protected debounce(fn: () => void, interval: number): void {
    this.globalDispatch('debounced:added');

    let debounced = this.#debounced.get(fn);
    if (!debounced) {
      const wrapper = () => {
        fn.bind(this)();
        this.#debounced.delete(fn);
        if (this.#debounced.size == 0) {
          this.globalDispatch('debounced:empty');
        }
      };

      debounced = debounce(wrapper.bind(this), interval);

      this.#debounced.set(fn, debounced);
    }
    debounced();
  }

  protected cancelDebounce(fn: () => void) {
    this.#debounced.get(fn)?.clear();
  }

  protected globalDispatch<T = Detail>(type: string, detail?: T): void {
    this.dispatch(type, {
      detail: detail as object,
      prefix: '',
      target: document.documentElement
    });
  }

  protected on<HandlerEvent extends Event = Event>(
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void {
    this.onTarget(this.element, eventName, handler);
  }

  protected onGlobal<HandlerEvent extends Event = Event>(
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void {
    this.onTarget(document.documentElement, eventName, handler);
  }

  private onTarget<HandlerEvent extends Event = Event>(
    target: EventTarget,
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void {
    const disconnect = this.disconnect;
    const callback = (event: Event): void => {
      handler(event as HandlerEvent);
    };
    target.addEventListener(eventName, callback);
    this.disconnect = () => {
      target.removeEventListener(eventName, callback);
      disconnect.call(this);
    };
  }
}
