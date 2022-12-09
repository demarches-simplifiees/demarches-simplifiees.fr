import { ApplicationController } from './application_controller';

export class BeforeunloadController extends ApplicationController {
  static values = { text: String };
  declare readonly textValue: string;

  connect() {
    this.onGlobal('autosave:enqueue', () => {
      window.addEventListener(
        'beforeunload',
        this.preventNavigationWhileAutoSaving
      );
    });
    this.onGlobal('autosave:end', () => {
      window.removeEventListener(
        'beforeunload',
        this.preventNavigationWhileAutoSaving
      );
    });
  }

  // see: https://github.com/gustavnikolaj/before-unload/blob/master/lib/BeforeUnload.js#L74
  private preventNavigationWhileAutoSaving(e: BeforeUnloadEvent) {
    (e || window.event).returnValue = this.textValue;
    return this.textValue;
  }
}
