import { ApplicationController } from './application_controller';

export class TextareaController extends ApplicationController {
  static values = {
    maxRows: Number
  };

  declare readonly maxRowsValue: number;

  connect() {
    if (this.maxRowsValue) {
      this.attachEvents();
    }
  }

  private attachEvents() {
    this.on('keyup', (event: KeyboardEvent) => {
      if (event.key === 'Enter') {
        this.processTextareaContent(event);
      }
    });

    this.on('paste', (event: ClipboardEvent) => {
      // Wait for the paste event to complete
      setTimeout(() => this.processTextareaContent(event), 0);
    });
  }

  private processTextareaContent(event: Event) {
    const target = event.target as HTMLTextAreaElement;
    let lines = target.value.split('\n');

    if (lines.length > this.maxRowsValue) {
      // Truncate lines to the maximum allowed
      lines = lines.slice(0, this.maxRowsValue);
      target.value = lines.join('\n');

      if (event instanceof KeyboardEvent) {
        // Prevent the default action only for KeyboardEvent (enter key)
        event.preventDefault();
      }
    }
  }
}
