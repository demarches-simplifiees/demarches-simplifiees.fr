import { httpRequest, ResponseError } from '@utils';
import invariant from 'tiny-invariant';

type Operation = {
  path: string;
  method: string;
  payload: unknown;
  resolve: (value: unknown) => void;
  reject: () => void;
};

export class OperationsQueue {
  queue: Operation[];
  isRunning = false;
  baseUrl: string;

  constructor(baseUrl: string) {
    this.queue = [];
    this.baseUrl = baseUrl;
  }

  async run() {
    if (this.queue.length > 0) {
      this.isRunning = true;
      const operation = this.queue.shift();
      invariant(operation, 'Operation is required');
      await this.exec(operation);
      this.run();
    } else {
      this.isRunning = false;
    }
  }

  enqueue(operation: Omit<Operation, 'resolve' | 'reject'>) {
    return new Promise((resolve, reject) => {
      this.queue.push({ ...operation, resolve, reject });
      if (!this.isRunning) {
        this.run();
      }
    });
  }

  async exec(operation: Operation) {
    const { path, method, payload, resolve, reject } = operation;
    const url = `${this.baseUrl}${path}`;

    try {
      const data = await httpRequest(url, { method, json: payload }).json();
      resolve(data);
    } catch (e) {
      handleError(e as ResponseError, reject);
    }
  }
}

async function handleError(
  { message, textBody, jsonBody }: ResponseError,
  reject: (error: string) => void
) {
  if (textBody) {
    reject(textBody);
  } else if (jsonBody) {
    const {
      errors: [message]
    } = jsonBody as { errors: string[] };
    reject(message);
  } else {
    reject(message);
  }
}
