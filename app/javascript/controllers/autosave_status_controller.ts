import {
  addClass,
  getConfig,
  hasClass,
  removeClass,
  ResponseError
} from '@utils';

import { ApplicationController } from './application_controller';

const {
  autosave: { status_visible_duration }
} = getConfig();
const AUTOSAVE_STATUS_VISIBLE_DURATION = status_visible_duration;

// This is a controller we attach to the status area in the main form. It
// coordinates notifications and will dispatch `autosave:retry` event if user
// decides to retry after an error.
//
export class AutosaveStatusController extends ApplicationController {
  connect(): void {
    this.onGlobal('autosave:enqueue', () => this.didEnqueue());
    this.onGlobal('autosave:end', () => this.didSucceed());
    this.onGlobal<CustomEvent>('autosave:error', (event) =>
      this.didFail(event)
    );

    this.onGlobal('debounced:added', () => this.debouncedAdded());
    this.onGlobal('debounced:empty', () => this.debouncedEmpty());
  }

  private debouncedAdded() {
    const autosave = this.element as HTMLDivElement;
    removeClass(autosave, 'debounced-empty');
    addClass(autosave, 'debounced-added');
  }

  private debouncedEmpty() {
    const autosave = this.element as HTMLDivElement;
    addClass(autosave, 'debounced-empty');
    removeClass(autosave, 'debounced-added');
  }

  private didEnqueue() {}

  private didSucceed() {
    this.setState('succeeded');
    this.debounce(this.hideSucceededStatus, AUTOSAVE_STATUS_VISIBLE_DURATION);
  }

  private didFail(event: CustomEvent<{ error: ResponseError }>) {
    const error = event.detail.error;

    if (error.response?.status == 401) {
      // If we are unauthenticated, reload the page using a GET request.
      // This will allow Devise to properly redirect us to sign-in, and then back to this page.
      document.location.reload();
      return;
    }

    this.setState('failed');

    const shouldLogError = !error.response || error.response.status != 0; // ignore timeout errors
    if (shouldLogError) {
      this.logError(error);
    }
  }

  private setState(state: 'succeeded' | 'failed' | 'idle') {
    const autosave = this.element as HTMLDivElement;
    if (autosave) {
      // Re-apply the state even if already present, to get a nice animation
      removeClass(autosave, 'autosave-state-idle');
      removeClass(autosave, 'autosave-state-succeeded');
      removeClass(autosave, 'autosave-state-failed');
      // eslint-disable-next-line @typescript-eslint/no-unused-expressions
      autosave.offsetHeight; // flush animations
      addClass(autosave, `autosave-state-${state}`);
    }
  }

  private hideSucceededStatus() {
    if (hasClass(this.element as HTMLElement, 'autosave-state-succeeded')) {
      this.setState('idle');
    }
  }

  private logError(error: ResponseError) {
    if (error && error.message) {
      console.error(error);
      this.globalDispatch('sentry:capture-exception', error);
    }
  }
}
