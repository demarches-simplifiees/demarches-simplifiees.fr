import { Controller } from '@hotwired/stimulus';
import debounce from 'debounce';
import invariant from 'tiny-invariant';

export type Detail = Record<string, unknown>;

// see: https://www.quirksmode.org/blog/archives/2008/04/delegating_the.html
const FOCUS_EVENTS = ['focus', 'blur'];

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
    target: EventTarget,
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void;
  protected on<HandlerEvent extends Event = Event>(
    eventName: string,
    handler: (event: HandlerEvent) => void
  ): void;
  protected on<HandlerEvent extends Event = Event>(
    targetOrEventName: EventTarget | string,
    eventNameOrHandler: string | ((event: HandlerEvent) => void),
    handler?: (event: HandlerEvent) => void
  ): void {
    if (typeof targetOrEventName == 'string') {
      invariant(typeof eventNameOrHandler != 'string', 'handler is required');
      this.onTarget(
        this.element,
        targetOrEventName,
        eventNameOrHandler,
        FOCUS_EVENTS.includes(targetOrEventName)
      );
    } else {
      invariant(
        typeof eventNameOrHandler == 'string',
        'event name is required'
      );
      invariant(handler, 'handler is required');
      this.onTarget(targetOrEventName, eventNameOrHandler, handler);
    }
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
    handler: (event: HandlerEvent) => void,
    capture?: boolean
  ): void {
    const disconnect = this.disconnect;
    const callback = (event: Event): void => {
      handler(event as HandlerEvent);
    };
    target.addEventListener(eventName, callback, capture);
    this.disconnect = () => {
      target.removeEventListener(eventName, callback, capture);
      disconnect.call(this);
    };
  }
}
