import { to, getJSON } from '@utils';

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
    const [data, xhr] = await to(getJSON(url, payload, method));

    if (xhr) {
      handleError(xhr, reject);
    } else {
      resolve(data);
    }
  }
}

function handleError(xhr, reject) {
  try {
    const {
      errors: [message]
    } = JSON.parse(xhr.responseText);
    reject(message);
  } catch (e) {
    reject(xhr.responseText);
  }
}
