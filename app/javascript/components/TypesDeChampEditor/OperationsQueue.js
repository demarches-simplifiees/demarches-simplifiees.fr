import { getJSON } from '@utils';

export default class OperationsQueue {
  constructor(baseUrl) {
    this.queue = [];
    this.isRunning = false;
    this.baseUrl = baseUrl;
  }

  async run() {
    if (this.queue.length > 0) {
      this.isRunning = true;
      const operation = this.queue.shift();
      await this.exec(operation);
      this.run();
    } else {
      this.isRunning = false;
    }
  }

  enqueue(operation) {
    return new Promise((resolve, reject) => {
      this.queue.push({ ...operation, resolve, reject });
      if (!this.isRunning) {
        this.run();
      }
    });
  }

  async exec(operation) {
    const { path, method, payload, resolve, reject } = operation;
    const url = `${this.baseUrl}${path}`;

    try {
      const data = await getJSON(url, payload, method);
      resolve(data);
    } catch (e) {
      handleError(e, reject);
    }
  }
}

async function handleError({ response, message }, reject) {
  if (response) {
    try {
      const {
        errors: [message]
      } = await response.json();
      reject(message);
    } catch {
      reject(await response.text());
    }
  } else {
    reject(message);
  }
}
