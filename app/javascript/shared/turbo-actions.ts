import { StreamActions, TurboStreamAction } from '@hotwired/turbo';
import morphdom from 'morphdom';

const hide: TurboStreamAction = function () {
  this.targetElements.forEach((element: Element) => {
    const delay = element.getAttribute('delay');
    const hide = () => element.classList.add('hidden');
    if (delay) {
      setTimeout(hide, parseInt(delay, 10));
    } else {
      hide();
    }
  });
};
const show: TurboStreamAction = function () {
  this.targetElements.forEach((element: Element) => {
    const delay = element.getAttribute('delay');
    const show = () => element.classList.remove('hidden');
    if (delay) {
      setTimeout(show, parseInt(delay, 10));
    } else {
      show();
    }
  });
};
const focus: TurboStreamAction = function () {
  this.targetElements.forEach((element: HTMLInputElement) => element.focus());
};
const disable: TurboStreamAction = function () {
  this.targetElements.forEach((element: HTMLInputElement) => {
    element.disabled = true;
  });
};
const enable: TurboStreamAction = function () {
  this.targetElements.forEach((element: HTMLInputElement) => {
    element.disabled = false;
  });
};
const morph: TurboStreamAction = function () {
  this.targetElements.forEach((element: Element) => {
    morphdom(element, this.templateContent, {
      onBeforeElUpdated(fromEl, toEl) {
        if (isTouchedInput(fromEl)) {
          fromEl.removeAttribute('data-touched');
          mergeInputValue(fromEl as HTMLInputElement, toEl as HTMLInputElement);
        }
        if (fromEl.isEqualNode(toEl)) {
          return false;
        }
        return true;
      }
    });
  });
};
const dispatch: TurboStreamAction = function () {
  const type = this.getAttribute('event-type') ?? '';
  const detail = this.getAttribute('event-detail');
  const event = new CustomEvent(type, {
    detail: JSON.parse(detail ?? '{}'),
    bubbles: true
  });
  document.documentElement.dispatchEvent(event);
};

StreamActions['hide'] = hide;
StreamActions['show'] = show;
StreamActions['focus'] = focus;
StreamActions['disable'] = disable;
StreamActions['enable'] = enable;
StreamActions['morph'] = morph;
StreamActions['dispatch'] = dispatch;

function mergeInputValue(fromEl: HTMLInputElement, toEl: HTMLInputElement) {
  toEl.value = fromEl.value;
  toEl.checked = fromEl.checked;
}

function isTouchedInput(element: HTMLElement): boolean {
  return (
    ['INPUT', 'TEXTAREA', 'SELECT'].includes(element.tagName) &&
    !!element.getAttribute('data-touched')
  );
}
