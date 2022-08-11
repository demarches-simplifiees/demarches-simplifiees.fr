/* eslint-disable react-hooks/rules-of-hooks */
import { ActionEvent } from '@hotwired/stimulus';
import {
  httpRequest,
  isSelectElement,
  isCheckboxOrRadioInputElement,
  isTextInputElement
} from '@utils';
import { useIntersection } from 'stimulus-use';
import { AutoUpload } from '../shared/activestorage/auto-upload';
import { ApplicationController } from './application_controller';

export class TypeDeChampEditorController extends ApplicationController {
  static values = {
    typeDeChampStableId: String,
    moveUrl: String,
    moveUpUrl: String,
    moveDownUrl: String
  };

  declare readonly moveUrlValue: string;
  declare readonly moveUpUrlValue: string;
  declare readonly moveDownUrlValue: string;
  declare readonly typeDeChampStableIdValue: string;
  declare readonly isVisible: boolean;

  #latestPromise = Promise.resolve();
  #dirtyForms: Set<HTMLFormElement> = new Set();
  #inFlightForms: Map<HTMLFormElement, AbortController> = new Map();

  connect() {
    useIntersection(this, { threshold: 0.6 });

    this.#latestPromise = Promise.resolve();
    this.on('change', (event) => this.onChange(event));
    this.on('input', (event) => this.onInput(event));
    this.on('sortable:end', (event) =>
      this.onSortableEnd(event as CustomEvent)
    );
  }

  disconnect() {
    this.#latestPromise = Promise.resolve();
    for (const [form] of this.#inFlightForms) {
      this.abortForm(form);
    }
    this.#inFlightForms.clear();
  }

  onMoveButtonClick(event: ActionEvent) {
    const { direction } = event.params;
    const action =
      direction == 'up' ? this.moveUpUrlValue : this.moveDownUrlValue;
    const form = createForm(action, 'patch');
    this.requestSubmitForm(form);
  }

  appear() {
    this.updateAfterId();
  }

  private onChange(event: Event) {
    const target = event.target as HTMLElement & { form?: HTMLFormElement };

    if (
      target.form &&
      (isSelectElement(target) || isCheckboxOrRadioInputElement(target))
    ) {
      this.save(target.form);
    }
  }

  private onInput(event: Event) {
    const target = event.target as HTMLInputElement;

    // mark input as touched so we know to not overwrite it's value with next re-render
    target.setAttribute('data-touched', 'true');

    if (target.form && isTextInputElement(target)) {
      this.#dirtyForms.add(target.form);
      this.debounce(this.save, 600);
    } else if (target.form && target.type == 'file' && target.files?.length) {
      const autoupload = new AutoUpload(target, target.files[0]);
      autoupload.start();
    }
  }

  private onSortableEnd(event: CustomEvent<{ position: number }>) {
    const position = event.detail.position;
    if (event.target == this.element) {
      const form = createForm(this.moveUrlValue, 'patch');
      createHiddenInput(form, 'position', position);
      this.requestSubmitForm(form);
    }
  }

  private save(form?: HTMLFormElement | null): void {
    if (form) {
      createHiddenInput(form, 'should_render', true);
    } else {
      this.element.querySelector('input[name="should_render"]')?.remove();
    }

    this.requestSubmitForm(form);
  }

  private requestSubmitForm(form?: HTMLFormElement | null) {
    if (form) {
      this.submitForm(form);
    } else {
      const forms = [...this.#dirtyForms];
      this.#dirtyForms.clear();

      for (const form of forms) {
        this.submitForm(form);
      }
    }
  }

  private submitForm(form: HTMLFormElement) {
    const controller = this.abortForm(form);

    this.#latestPromise = this.#latestPromise.finally(() =>
      httpRequest(form.action, {
        method: form.getAttribute('method') ?? '',
        body: new FormData(form),
        controller: controller
      })
        .turbo()
        .catch(() => null)
    );
  }

  private abortForm(form: HTMLFormElement) {
    const controller = new AbortController();
    this.#inFlightForms.get(form)?.abort();
    this.#inFlightForms.set(form, controller);
    return controller;
  }

  private updateAfterId() {
    const parent = this.element.closest<HTMLElement>(
      '.editor-block, .editor-root'
    );
    if (parent) {
      const selector = parent.classList.contains('editor-block')
        ? '.add-to-block'
        : '.add-to-root';
      const input = parent.querySelector<HTMLInputElement>(
        `${selector} ${AFTER_STABLE_ID_INPUT_SELECTOR}`
      );
      if (input) {
        input.value = this.typeDeChampStableIdValue;
      }
    }
  }
}

const AFTER_STABLE_ID_INPUT_SELECTOR =
  'input[name="type_de_champ[after_stable_id]"]';

function createForm(action: string, method: string) {
  const form = document.createElement('form');
  form.action = action;
  form.method = 'post';
  createHiddenInput(form, '_method', method);
  return form;
}

function createHiddenInput(
  form: HTMLFormElement,
  name: string,
  value: unknown
) {
  const input = document.createElement('input');
  input.type = 'hidden';
  input.name = name;
  input.value = String(value);
  form.appendChild(input);
}
