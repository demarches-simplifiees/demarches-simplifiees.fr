import { httpRequest } from '@utils';

import { ApplicationController } from './application_controller';

const DEFAULT_POLL_INTERVAL = 3000;
const DEFAULT_MAX_CHECKS = 20;

// Periodically check the state of a URL.
//
// Each time the given URL is requested, a turbo-stream is rendered, causing the state to be refreshed.
//
// This is used mainly to refresh attachments during the anti-virus check,
// but also to refresh the state of a pending spreadsheet export.
export class TurboPollController extends ApplicationController {
  static values = {
    url: String,
    maxChecks: { type: Number, default: DEFAULT_MAX_CHECKS },
    interval: { type: Number, default: DEFAULT_POLL_INTERVAL }
  };

  declare readonly urlValue: string;
  declare readonly intervalValue: number;
  declare readonly maxChecksValue: number;

  #timer?: ReturnType<typeof setTimeout>;
  #abortController?: AbortController;

  connect(): void {
    this.schedule();
  }

  disconnect(): void {
    this.cancel();
  }

  refresh() {
    this.#abortController = new AbortController();

    httpRequest(this.urlValue, { signal: this.#abortController.signal })
      .turbo()
      .catch(() => null);
  }

  private schedule(): void {
    this.cancel();
    this.#timer = setInterval(() => {
      const nextState = this.nextState();

      if (!nextState) {
        this.cancel();
      } else {
        this.refresh();
      }
    }, this.intervalValue);
  }

  private cancel(): void {
    clearInterval(this.#timer);
    this.#abortController?.abort();
    this.#abortController = window.AbortController
      ? new AbortController()
      : undefined;
  }

  private nextState(): PollState | false {
    const state = pollers.get(this.urlValue);

    if (!state) {
      return this.resetState();
    }

    state.checks += 1;
    if (state.checks <= this.maxChecksValue) {
      return state;
    } else {
      this.resetState();
      return false;
    }
  }

  private resetState(): PollState {
    const state = {
      interval: this.intervalValue,
      checks: 0
    };
    pollers.set(this.urlValue, state);
    return state;
  }
}

type PollState = {
  checks: number;
};

// We keep a global state of the pollers. It will be reset on every page change.
const pollers = new Map<string, PollState>();
