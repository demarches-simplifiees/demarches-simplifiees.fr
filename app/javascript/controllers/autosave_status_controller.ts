import {
  enable,
  disable,
  hasClass,
  addClass,
  removeClass,
  ResponseError,
  getConfig,
  httpRequest
} from '@utils';

import { ApplicationController } from './application_controller';

type AutosaveEnqueueEvent = CustomEvent<{ url: string; formData: FormData }>;
type AutosaveErrorEvent = CustomEvent<{ error: ResponseError }>;

const {
  autosave: { status_visible_duration, debounce_delay }
} = getConfig();

const AUTOSAVE_STATUS_VISIBLE_DURATION = status_visible_duration;
const AUTOSAVE_DEBOUNCE_DELAY = debounce_delay;
const AUTOSAVE_TIMEOUT_DELAY = 60000;

// This is a controller we attach to the status area in the main form. It
// coordinates notifications and will dispatch `autosave:retry` event if user
// decides to retry after an error.
//
export class AutosaveStatusController extends ApplicationController {
  static targets = ['retryButton'];

  declare readonly retryButtonTarget: HTMLButtonElement;

  #abortController?: AbortController;
  #latestPromise = Promise.resolve();
  #nextFormData = new FormData();
  #inFlightFormData = new FormData();
  #formAction?: string;

  connect(): void {
    this.onGlobal<AutosaveEnqueueEvent>('autosave:enqueue', (event) =>
      this.didEnqueue(event.detail)
    );
    this.onGlobal<AutosaveErrorEvent>('autosave:error', (event) =>
      this.didFail(event.detail)
    );
  }

  disconnect() {
    this.#abortController?.abort();
    this.#latestPromise = Promise.resolve();
  }

  onClickRetryButton() {
    this.debounce(this.enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY);
  }

  private didEnqueue(detail: AutosaveEnqueueEvent['detail']) {
    this.#formAction = detail.url;
    detail.formData.forEach((value, key) =>
      this.#nextFormData.append(key, value)
    );

    disable(this.retryButtonTarget);
    this.debounce(this.enqueueAutosaveRequest, AUTOSAVE_DEBOUNCE_DELAY);
  }

  private enqueueAutosaveRequest() {
    this.#latestPromise = this.#latestPromise.finally(() =>
      this.sendAutosaveRequest()
        .then(() => this.didSucceed())
        .catch((error) => this.didFail({ error }))
        .finally(() => this.didEnd())
    );
  }

  private sendAutosaveRequest(): Promise<void> {
    if (!this.#formAction) {
      return Promise.resolve();
    }

    const formData = (this.#inFlightFormData = this.#nextFormData);
    this.#abortController = new AbortController();
    this.#nextFormData = new FormData();

    return httpRequest(this.#formAction, {
      method: 'patch',
      body: formData,
      controller: this.#abortController,
      timeout: AUTOSAVE_TIMEOUT_DELAY
    }).turbo();
  }

  private didEnd() {
    this.#inFlightFormData = new FormData();
    enable(this.retryButtonTarget);
  }

  private didSucceed() {
    this.setState('succeeded');
    this.debounce(this.hideSucceededStatus, AUTOSAVE_STATUS_VISIBLE_DURATION);
  }

  private didFail(detail: AutosaveErrorEvent['detail']) {
    const error = detail.error;

    if (error.response?.status == 401) {
      // If we are unauthenticated, reload the page using a GET request.
      // This will allow Devise to properly redirect us to sign-in, and then back to this page.
      document.location.reload();
      return;
    }

    const formData = new FormData();
    this.#inFlightFormData.forEach((value, key) => formData.append(key, value));
    this.#nextFormData.forEach((value, key) => formData.append(key, value));
    this.#nextFormData = formData;

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
