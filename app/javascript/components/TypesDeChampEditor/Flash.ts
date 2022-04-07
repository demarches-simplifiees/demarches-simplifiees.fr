import invariant from 'tiny-invariant';

export class Flash {
  element: HTMLDivElement;
  isAnnotation: boolean;
  timeout?: number;

  constructor(isAnnotation: boolean) {
    const element = document.querySelector<HTMLDivElement>('#flash_messages');
    invariant(element, 'Flash element is required');
    this.element = element;
    this.isAnnotation = isAnnotation;
  }
  success() {
    if (this.isAnnotation) {
      this.add('Annotations privées enregistrées.');
    } else {
      this.add('Formulaire enregistré.');
    }
  }
  error(message: string) {
    this.add(message, true);
  }
  clear() {
    this.element.innerHTML = '';
  }
  add(message: string, isError = false) {
    const html = `<div id="flash_message" class="center">
      <div class="alert alert-fixed ${
        isError ? 'alert-danger' : 'alert-success'
      }">
        ${message}
      </div>
    </div>`;

    this.element.innerHTML = html;

    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.clear();
    }, 4000);
  }
}
