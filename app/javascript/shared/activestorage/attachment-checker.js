import { ajax, delegate } from '@utils';

addEventListener('turbolinks:load', () => {
  checker.deactivate();

  const attachments = document.querySelectorAll('[data-attachment-check-url]');

  for (let attachment of attachments) {
    checker.add(attachment.dataset.attachmentCheckUrl);
  }
});

addEventListener('attachment:update', ({ detail: { url } }) => {
  checker.add(url);
});

delegate('click', '[data-attachment-refresh]', event => {
  event.preventDefault();
  checker.check();
});

class AttachmentChecker {
  urls = new Set();
  timeout;
  checks = 0;

  constructor(settings = {}) {
    this.interval = settings.interval || 5000;
    this.maxChecks = settings.maxChecks || 5;
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
      this.check();
    }, this.interval);
  }

  deactivate() {
    this.checks = 0;
    this.reset();
  }

  reset() {
    clearTimeout(this.timeout);
    this.urls = new Set();
    this.timeout = undefined;
  }
}

const checker = new AttachmentChecker();
