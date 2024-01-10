import { ApplicationController } from './application_controller';

export class TextareaController extends ApplicationController {
  static values = {
    maxRows: Number
  };

  declare readonly maxRowsValue: number;

  connect() {
    if (this.maxRowsValue) {
      this.limitMaxRows();
    }
  }

  private limitMaxRows() {
    this.on('keydown', (event: KeyboardEvent) => {
      const target = event.target as HTMLTextAreaElement;
      const lines = target.value.split('\n');

      if (event.key === 'Enter' && lines.length >= this.maxRowsValue) {
        event.preventDefault(); // Prevent the newline if max rows reached
      }
    });
  }
}
