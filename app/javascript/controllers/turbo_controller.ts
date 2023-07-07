import { Actions } from '@coldwired/actions';
import { parseTurboStream } from '@coldwired/turbo-stream';
import invariant from 'tiny-invariant';
import { session as TurboSession, type StreamElement } from '@hotwired/turbo';

import { ApplicationController } from './application_controller';

type StreamRenderEvent = CustomEvent<{
  render(streamElement: StreamElement): void;
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
      element: document.documentElement,
      schema: { forceAttribute: 'data-turbo-force', hiddenClassName: 'hidden' }
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

    // reset state preserved for actions between pages
    this.onGlobal('turbo:load', () => this.actions.reset());

    // see: https://turbo.hotwired.dev/handbook/streams#custom-actions
    this.onGlobal('turbo:before-stream-render', (event: StreamRenderEvent) => {
      const fallbackToDefaultActions = event.detail.render;
      event.detail.render = (streamElement: StreamElement) =>
        this.renderStreamElement(streamElement, fallbackToDefaultActions);
    });
  }

  private renderStreamElement(
    streamElement: StreamElement,
    fallbackRender: (streamElement: StreamElement) => void
  ) {
    switch (streamElement.action) {
      // keep turbo default behavior to avoid risks going all in on coldwire
      case 'replace':
      case 'update':
        fallbackRender(streamElement);
        break;
      case 'morph':
        streamElement.setAttribute('action', 'replace');
        this.actions.applyActions([parseTurboStream(streamElement)]);
        break;
      default:
        this.actions.applyActions([parseTurboStream(streamElement)]);
    }
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
