import { httpRequest } from '@utils';

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
    interval: Number
  };

  declare readonly urlValue: string;
  declare readonly strategyValue: PollingStrategy;
  declare readonly intervalValue?: number;

  #stop?: () => void;

  connect(): void {
    this.#stop = startPolling((signal) => this.refresh(signal), {
      strategy: this.strategyValue,
      baseDelay: this.intervalValue,
      jitter: true
    });
  }

  disconnect(): void {
    this.#stop?.();
  }

  async refresh(signal?: AbortSignal) {
    await httpRequest(this.urlValue, { signal }).turbo();
  }
}

type PollingStrategy =
  | 'fixed'
  | 'linear'
  | 'exponential'
  | 'fibonacci'
  | 'randomized';

interface PollOptions {
  strategy: PollingStrategy;
  baseDelay?: number;
  maxDelay?: number;
  jitter?: boolean;
}

function startPolling(
  fn: (signal: AbortSignal) => Promise<void>,
  { strategy, baseDelay = 1000, maxDelay = 30_000, jitter = false }: PollOptions
) {
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout>;
  let attempt = 0;
  const fib = [baseDelay, baseDelay];

  const nextDelay = (): number => {
    let delay: number;

    switch (strategy) {
      case 'fixed':
        delay = baseDelay;
        break;
      case 'linear':
        delay = baseDelay * (attempt + 1);
        break;
      case 'exponential':
        delay = baseDelay * 2 ** attempt;
        break;
      case 'fibonacci':
        if (attempt < 2) {
          delay = fib[attempt];
        } else {
          fib[attempt] = fib[attempt - 1] + fib[attempt - 2];
          delay = fib[attempt];
        }
        break;
      case 'randomized':
        delay = baseDelay + Math.random() * baseDelay;
        break;
      default:
        delay = baseDelay;
    }

    if (jitter && strategy !== 'randomized') {
      delay += Math.random() * baseDelay;
    }

    return Math.min(delay, maxDelay);
  };

  const poll = async () => {
    try {
      await fn(controller.signal);
    } catch (error) {
      console.error('Polling error:', error);
    }

    attempt++;
    const delay = nextDelay();
    timer = setTimeout(poll, delay);
  };

  poll();

  return () => {
    clearTimeout(timer);
    controller.abort();
  };
}
