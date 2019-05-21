import Rails from 'rails-ujs';

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

  activate() {
    this.timeout = setTimeout(() => {
      for (let url of this.urls) {
        Rails.ajax({ url, type: 'get' });
      }
      this.checks++;
      this.reset();
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
