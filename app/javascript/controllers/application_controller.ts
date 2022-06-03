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

  protected globalDispatch<T = Detail>(type: string, detail?: T): void {
    this.dispatch(type, {
      detail,
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
