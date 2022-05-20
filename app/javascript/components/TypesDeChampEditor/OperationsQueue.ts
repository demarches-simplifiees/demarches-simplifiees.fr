import { httpRequest } from '@utils';
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
      handleError(e as OperationError, reject);
    }
  }
}

class OperationError extends Error {
  response?: Response;
}

async function handleError(
  { response, message }: OperationError,
  reject: (error: string) => void
) {
  if (response) {
    try {
      const {
        errors: [message]
      } = await response.clone().json();
      reject(message);
    } catch {
      reject(await response.text());
    }
  } else {
    reject(message);
  }
}
