import invariant from 'tiny-invariant';
import { z } from 'zod';
import morphdom from 'morphdom';

import { ApplicationController, Detail } from './application_controller';

export class TurboEventController extends ApplicationController {
  static values = {
    type: String,
    detail: Object
  };

  declare readonly typeValue: string;
  declare readonly detailValue: Detail;

  connect(): void {
    this.globalDispatch(this.typeValue, this.detailValue);
    this.element.remove();
  }
}

const MutationAction = z.enum([
  'show',
  'hide',
  'focus',
  'enable',
  'disable',
  'morph'
]);
type MutationAction = z.infer<typeof MutationAction>;
const Mutation = z.union([
  z.object({
    action: MutationAction,
    delay: z.number().optional(),
    target: z.string(),
    html: z.string().optional()
  }),
  z.object({
    action: MutationAction,
    delay: z.number().optional(),
    targets: z.string(),
    html: z.string().optional()
  })
]);
type Mutation = z.infer<typeof Mutation>;

addEventListener('dom:mutation', (event) => {
  const detail = (event as CustomEvent).detail;
  const mutation = Mutation.parse(detail);
  mutate(mutation);
});

const Mutations: Record<MutationAction, (mutation: Mutation) => void> = {
  hide: (mutation) => {
    for (const element of findElements(mutation)) {
      element.classList.add('hidden');
    }
  },
  show: (mutation) => {
    for (const element of findElements(mutation)) {
      element.classList.remove('hidden');
    }
  },
  focus: (mutation) => {
    for (const element of findElements(mutation)) {
      element.focus();
    }
  },
  disable: (mutation) => {
    for (const element of findElements<HTMLInputElement>(mutation)) {
      element.disabled = true;
    }
  },
  enable: (mutation) => {
    for (const element of findElements<HTMLInputElement>(mutation)) {
      element.disabled = false;
    }
  },
  morph: (mutation) => {
    invariant(mutation.html, 'morph action requires html');
    for (const element of findElements<HTMLInputElement>(mutation)) {
      morphdom(element, mutation.html, {
        onBeforeElUpdated(fromEl, toEl) {
          if (isTouchedInput(fromEl)) {
            fromEl.removeAttribute('data-touched');
            mergeInputValue(
              fromEl as HTMLInputElement,
              toEl as HTMLInputElement
            );
          }
          if (fromEl.isEqualNode(toEl)) {
            return false;
          }
          return true;
        }
      });
    }
  }
};

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

function mutate(mutation: Mutation) {
  const fn = Mutations[mutation.action];
  invariant(fn, `Could not find mutation ${mutation.action}`);
  if (mutation.delay) {
    setTimeout(() => fn(mutation), mutation.delay);
  } else {
    fn(mutation);
  }
}

function findElements<Element extends HTMLElement = HTMLElement>(
  mutation: Mutation
): Element[] {
  if ('target' in mutation) {
    const element = document.querySelector<Element>(`#${mutation.target}`);
    invariant(element, `Could not find element with id ${mutation.target}`);
    return [element];
  } else if ('targets' in mutation) {
    return [...document.querySelectorAll<Element>(mutation.targets)];
  }
  invariant(false, 'Could not find element');
}
