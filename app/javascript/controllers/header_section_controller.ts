import { ApplicationController } from '~/controllers/application_controller';

export class HeaderSectionController extends ApplicationController {
  connect(): void {
    const target = this.element as HTMLInputElement;
    const tagName = target.tagName;
    console.log(tagName);
    if (tagName == 'H2' || tagName == 'H3') {
      const className = 'header-section-reset' + tagName[1];
      target.parentElement?.classList.add(className);
    }
  }
}
