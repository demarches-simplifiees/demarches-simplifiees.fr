import { ajax, delegate } from '@utils';

addEventListener('turbolinks:load', () => {
  attachementPoller.deactivate();
  exportPoller.deactivate();

  const attachments = document.querySelectorAll('[data-attachment-poll-url]');
  const exports = document.querySelectorAll('[data-export-poll-url]');

  for (let { dataset } of attachments) {
    attachementPoller.add(dataset.attachmentPollUrl);
  }

  for (let { dataset } of exports) {
    exportPoller.add(dataset.exportPollUrl);
  }
});

addEventListener('attachment:update', ({ detail: { url } }) => {
  attachementPoller.add(url);
});

addEventListener('export:update', ({ detail: { url } }) => {
  exportPoller.add(url);
});

delegate('click', '[data-attachment-refresh]', event => {
  event.preventDefault();
  attachementPoller.check();
});

class RemotePoller {
  urls = new Set();
  timeout;
  checks = 0;

  constructor(settings = {}) {
    this.interval = settings.interval;
    this.maxChecks = settings.maxChecks;
  }

  get isEnabled() {
    return this.checks <= this.maxChecks;
  }

  get isActive() {
    return this.timeout !== undefined;
  }

  add(url) {
    if (this.isEnabled) {
      if (!this.isActive) {
        this.activate();
      }
      this.urls.add(url);
    }
  }

  check() {
    let urls = this.urls;
    this.reset();
    for (let url of urls) {
      ajax({ url, type: 'get' });
    }
  }

  activate() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.checks++;
      this.currentInterval = this.interval * 1.5;
      this.check();
    }, this.currentInterval);
  }

  deactivate() {
    this.checks = 0;
    this.currentInterval = this.interval;
    this.reset();
  }

  reset() {
    clearTimeout(this.timeout);
    this.urls = new Set();
    this.timeout = undefined;
  }
}

const attachementPoller = new RemotePoller({ interval: 2000, maxChecks: 5 });
const exportPoller = new RemotePoller({ interval: 4000, maxChecks: 10 });
