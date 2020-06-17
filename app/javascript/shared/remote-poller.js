import { ajax, delegate } from '@utils';

addEventListener('DOMContentLoaded', () => {
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

delegate('click', '[data-attachment-refresh]', (event) => {
  event.preventDefault();
  attachementPoller.check();
});

// Periodically check the state of a set of URLs.
//
// Each time the given URL is requested, the matching `show.js.erb` view is rendered,
// causing the state to be refreshed.
//
// This is used mainly to refresh attachments during the anti-virus check,
// but also to refresh the state of a pending spreadsheet export.
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
      // Start the request. The JS payload in the response will update the page.
      // (Errors are ignored, because background tasks shouldn't report errors to the user.)
      ajax({ url, type: 'get' }).catch(() => {});
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

const attachementPoller = new RemotePoller({ interval: 3000, maxChecks: 5 });
const exportPoller = new RemotePoller({ interval: 6000, maxChecks: 10 });
