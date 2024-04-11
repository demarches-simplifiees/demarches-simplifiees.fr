import { ApplicationController } from './application_controller';

export class SelectChampPositionTemplateController extends ApplicationController {
  static targets = ['select', 'template'];
  static values = {
    templateId: String
  };
  // this element is updated via turbostream as the source of truth for all select
  declare readonly templateIdValue: string;
  declare readonly selectTargets: HTMLSelectElement[];

  selectTargetConnected(selectElement: HTMLSelectElement) {
    selectElement.addEventListener('focus', this);
    selectElement.addEventListener('change', this);
  }

  selectTargetDisconnected(selectElement: HTMLSelectElement) {
    selectElement.removeEventListener('focus', this);
    selectElement.removeEventListener('change', this);
  }

  handleEvent(event: Event) {
    switch (event.type) {
      case 'focus':
        this.onFocus(event);
        break;
      case 'change':
        this.onChange(event);
        break;
    }
  }

  private onFocus(event: Event): void {
    const focusedSelect = event.target as HTMLSelectElement;
    const focusedSelectStableId = this.getStableIdForSelect(focusedSelect);
    const template = this.element.querySelector<HTMLElement>(
      `#${this.templateIdValue}`
    );

    if (template) {
      const fragment = template.cloneNode(true) as HTMLSelectElement;

      const options = Array.from(fragment.querySelectorAll('option'));
      options.map((option) => {
        // can't move current element after current element
        if (option.value == focusedSelectStableId) {
          option.setAttribute('selected', 'selected');
          option.setAttribute('disabled', 'disabled');
        }
      });

      focusedSelect.innerHTML = options
        .map((option) => option.outerHTML)
        .join('');
    }
  }

  private onChange(event: Event): void {
    const changedSelectTarget = event.target as HTMLSelectElement;
    const stableIdDidChange =
      changedSelectTarget.value !=
      this.getStableIdForSelect(changedSelectTarget);
    if (stableIdDidChange) {
      changedSelectTarget.form?.requestSubmit();
    }
    event.stopImmediatePropagation();
  }

  private getStableIdForSelect(select: HTMLSelectElement): string | null {
    return select.getAttribute('data-selected');
  }
}
