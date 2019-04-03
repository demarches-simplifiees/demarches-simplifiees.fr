export default class Flash {
  constructor(isAnnotation) {
    this.element = document.querySelector('#flash_messages');
    this.isAnnotation = isAnnotation;
  }
  success() {
    if (this.isAnnotation) {
      this.add('Annotations privées enregistrées.');
    } else {
      this.add('Formulaire enregistré.');
    }
  }
  error(message) {
    this.add(message, true);
  }
  clear() {
    this.element.innerHTML = '';
  }
  add(message, isError) {
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
