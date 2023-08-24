import { Actions } from '@coldwired/actions';
import { parseTurboStream } from '@coldwired/turbo-stream';
import invariant from 'tiny-invariant';
import { session as TurboSession, type StreamElement } from '@hotwired/turbo';

import { ApplicationController } from './application_controller';

type StreamRenderEvent = CustomEvent<{
  render(streamElement: StreamElement): void;
}>;

type FrameRenderEvent = CustomEvent<{
  render(currentElement: Element, newElement: Element): void;
}>;

export class TurboController extends ApplicationController {
  static targets = ['spinner'];

  declare readonly spinnerTargets: HTMLElement[];

  #submitting = false;
  #actions?: Actions;

  // `actions` instrface exposes all available actions as methods and also `applyActions` method
  // wich allows to apply a batch of actions. On top of regular `turbo-stream` actions we also
  // expose `focus`, `enable`, `disable`, `show` and `hide` actions. Each action take a `targets`
  // option (wich can be a CSS selector or a list of DOM nodes) and a `fragment` option (wich is a
  // `DocumentFragment` and only required on "rendering" actions).
  get actions() {
    invariant(this.#actions, 'Actions not initialized');
    return this.#actions;
  }

  connect() {
    this.#actions = new Actions({
      element: document.body,
      schema: {
        forceAttribute: 'data-turbo-force',
        focusGroupAttribute: 'data-turbo-focus-group',
        focusDirectionAttribute: 'data-turbo-focus-direction',
        hiddenClassName: 'hidden'
      },
      debug: false
    });

    // actions#observe() is an interface over specialized mutation observers.
    // They allow us to preserve certain HTML changes across mutations.
    this.#actions.observe();

    // setup spinner events
    this.onGlobal('turbo:submit-start', () => this.startSpinner());
    this.onGlobal('turbo:submit-end', () => this.stopSpinner());
    this.onGlobal('turbo:fetch-request-error', () => this.stopSpinner());

    // prevent scroll on turbo form submits
    this.onGlobal('turbo:render', () => this.preventScrollIfNeeded());

    // see: https://turbo.hotwired.dev/handbook/streams#custom-actions
    this.onGlobal('turbo:before-stream-render', (event: StreamRenderEvent) => {
      event.detail.render = (streamElement: StreamElement) =>
        this.actions.applyActions([parseTurboStream(streamElement)]);
    });

    // see: https://turbo.hotwired.dev/handbook/frames#custom-rendering
    this.onGlobal('turbo:before-frame-render', (event: FrameRenderEvent) => {
      event.detail.render = (currentElement, newElement) => {
        // There is a bug in morphdom when it comes to mutate a custom element. It will miserably
        // crash. We mutate its content instead.
        const fragment = document.createDocumentFragment();
        fragment.append(...newElement.childNodes);
        this.actions.update({ targets: [currentElement], fragment });
      };
    });
  }

  private startSpinner() {
    this.#submitting = true;
    this.actions.show({ targets: this.spinnerTargets });
  }

  private stopSpinner() {
    this.#submitting = false;
    this.actions.hide({ targets: this.spinnerTargets });
  }

  private preventScrollIfNeeded() {
    if (this.#submitting && TurboSession.navigator.currentVisit) {
      TurboSession.navigator.currentVisit.scrolled = true;
    }
  }
}
