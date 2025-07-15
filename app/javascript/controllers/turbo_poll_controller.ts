import { httpRequest } from '@utils';

import { startPolling, type PollingStrategy } from '~/shared/polling';
import { ApplicationController } from './application_controller';

// Periodically check the state of a URL.
//
// Each time the given URL is requested, a turbo-stream is rendered, causing the state to be refreshed.
//
// This is used mainly to refresh attachments during the anti-virus check,
// but also to refresh the state of a pending spreadsheet export.
export class TurboPollController extends ApplicationController {
  static values = {
    url: String,
    strategy: { type: String, default: 'fibonacci' },
    interval: { type: Number, default: 2000 }
  };

  declare readonly urlValue: string;
  declare readonly strategyValue: PollingStrategy;
  declare readonly intervalValue?: number;

  #stop?: () => void;

  connect(): void {
    this.#stop = startPolling((signal) => this.refresh(signal), {
      strategy: this.strategyValue,
      baseDelay: this.intervalValue,
      jitter: true,
      isActive: () => !document.hidden
    });
  }

  disconnect(): void {
    this.#stop?.();
  }

  async refresh(signal?: AbortSignal) {
    await httpRequest(this.urlValue, { signal }).turbo();
  }
}
