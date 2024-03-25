import { ApplicationController } from './application_controller';
export class FileInputResetController extends ApplicationController {
  static targets = ['fileList'];
  declare fileListTarget: HTMLElement;

  connect() {
    super.connect();
    this.updateFileList();
    this.element.addEventListener('change', (event) => {
      if (
        event.target instanceof HTMLInputElement &&
        event.target.type === 'file'
      ) {
        this.updateFileList();
      }
    });
  }

  updateFileList() {
    const files = this.fileInput?.files ?? [];
    this.fileListTarget.innerHTML = '';

    const deleteLabel =
      this.element.getAttribute('data-delete-label') || 'Delete';

    Array.from(files).forEach((file, index) => {
      const container = document.createElement('div');
      container.style.display = 'flex';
      container.style.alignItems = 'center';

      const deleteButton = this.createDeleteButton(deleteLabel, index);
      container.appendChild(deleteButton);

      const listItem = document.createElement('li');
      listItem.textContent = file.name;
      listItem.style.listStyle = 'none';
      listItem.style.marginLeft = '8px'; // Adjust the spacing as needed

      container.appendChild(listItem);
      this.fileListTarget.appendChild(container);
    });
  }

  createDeleteButton(deleteLabel: string, index: number) {
    const button = document.createElement('button');
    button.textContent = deleteLabel;
    button.classList.add(
      'fr-btn',
      'fr-btn--tertiary',
      'fr-btn--sm',
      'fr-icon-delete-line'
    );

    button.addEventListener('click', (event) => {
      event.preventDefault();
      this.removeFile(index);
    });

    return button;
  }

  removeFile(index: number) {
    const files = this.fileInput?.files;
    if (!files) return;

    const dataTransfer = new DataTransfer();
    Array.from(files).forEach((file, i) => {
      if (index !== i) {
        dataTransfer.items.add(file);
      }
    });

    if (this.fileInput) this.fileInput.files = dataTransfer.files;
    this.updateFileList();
  }

  private get fileInput(): HTMLInputElement | null {
    return this.element.querySelector(
      'input[type="file"]'
    ) as HTMLInputElement | null;
  }
}
