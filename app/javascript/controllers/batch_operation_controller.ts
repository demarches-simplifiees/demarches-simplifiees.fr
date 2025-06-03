import { ApplicationController } from './application_controller';
import { disable, enable, show, hide } from '@utils';
import invariant from 'tiny-invariant';

export class BatchOperationController extends ApplicationController {
  static targets = ['menu', 'input', 'dropdown', 'checkboxCount', 'modalForm'];

  declare readonly menuTargets: HTMLButtonElement[];
  declare readonly inputTargets: HTMLInputElement[];
  declare readonly dropdownTargets: HTMLButtonElement[];
  declare readonly checkboxCountTarget: HTMLElement;
  declare readonly modalFormTarget: HTMLFormElement;
  declare readonly hasModalFormTarget: boolean;

  onCheckOne() {
    this.toggleSubmitButtonWhenNeeded();
    this.updateCheckboxCount();
    deleteSelection();
  }

  onCheckAll(event: Event) {
    const target = event.target as HTMLInputElement;

    this.inputTargets.forEach((e) => {
      e.checked = target.checked;
      e.dispatchEvent(new Event('change')); // dispatch change for dsfr checkbox behavior
    });

    this.toggleSubmitButtonWhenNeeded();
    this.updateCheckboxCount();

    const pagination = document.querySelector(
      '.fr-table__footer .fr-pagination'
    );
    if (pagination) {
      displayNotice(this.inputTargets);
    }

    // add focus on button for a11y
    const button = document.getElementById('js_select_more');
    if (button) {
      button.focus();
    }
  }

  onSelectMore(event: {
    preventDefault: () => void;
    target: HTMLInputElement;
  }) {
    event.preventDefault();

    const target = event.target as HTMLInputElement;
    const dossierIds = target.getAttribute('data-dossiers');

    const hidden_input_multiple_ids = document.querySelector<HTMLInputElement>(
      '#input_multiple_ids_batch_operation'
    );
    if (hidden_input_multiple_ids) {
      hidden_input_multiple_ids.value = dossierIds || '';
    }

    hide(document.querySelector('#not_selected'));
    show(document.querySelector('#selected'));

    // add focus on button for a11y
    const button = document.getElementById('js_delete_selection');
    if (button) {
      button.focus();
    }

    this.updateCheckboxCount();
  }

  onSubmitInstruction(event: { srcElement: HTMLInputElement }) {
    const field_refuse = document.querySelector<HTMLInputElement>(
      '.js_batch_operation_motivation_refuse'
    );

    const field_without_continuation = document.querySelector<HTMLInputElement>(
      '.js_batch_operation_motivation_without-continuation'
    );

    if (field_refuse != null) {
      if (event.srcElement.value == 'refuser' && field_refuse.value == '') {
        field_refuse.setCustomValidity('La motivation doit être remplie');
      } else {
        field_refuse.setCustomValidity('');
      }
    }

    if (field_without_continuation != null) {
      if (
        event.srcElement.value == 'classer_sans_suite' &&
        field_without_continuation.value == ''
      ) {
        field_without_continuation.setCustomValidity(
          'La motivation doit être remplie'
        );
      } else {
        field_without_continuation.setCustomValidity('');
      }
    }
  }

  onDeleteSelection(event: { preventDefault: () => void }) {
    event.preventDefault();
    emptyCheckboxes();
    deleteSelection();
    this.toggleSubmitButtonWhenNeeded();
    this.updateCheckboxCount();
  }

  toggleSubmitButtonWhenNeeded() {
    const buttons = [
      ...this.element.querySelectorAll<HTMLButtonElement>('[data-operation]')
    ];
    const checked = this.inputTargets.filter((input) => input.checked);
    if (checked.length) {
      const available = buttons.filter((button) => {
        const operation = button.dataset.operation;
        invariant(operation, 'data-operation is required');
        const available = checked.every(isInputForOperation(operation));
        switchButton(button, available);
        return available;
      });

      if (this.menuTargets.length) {
        if (available.length) {
          this.menuTargets.forEach((e) => enable(e));
        } else {
          this.menuTargets.forEach((e) => disable(e));
        }
      }

      this.dropdownTargets.forEach((dropdown) => {
        const buttons = Array.from(
          document.querySelectorAll<HTMLButtonElement>(
            `[aria-labelledby='${dropdown.id}'] button[data-operation]`
          )
        );

        const disabled = buttons.every((button) => button.disabled);

        if (disabled) {
          disable(dropdown);
        } else {
          enable(dropdown);
        }
      });

      // pour chaque chaque dropdown, on va chercher tous les boutons
      // si tous les boutons sont disabled, on disable le dropdown
    } else {
      this.menuTargets.forEach((e) => disable(e));
      buttons.forEach((button) => switchButton(button, false));

      this.dropdownTargets.forEach((e) => disable(e));
    }
  }

  updateCheckboxCount() {
    if (!this.checkboxCountTarget) return;

    // Use hidden input value if present
    const hiddenInput = document.querySelector<HTMLInputElement>(
      '#input_multiple_ids_batch_operation'
    );

    let count = 0;

    if (hiddenInput && hiddenInput.value.trim() !== '') {
      const ids = hiddenInput.value.split(',').filter((id) => id.trim() !== '');
      count = ids.length;
    } else {
      // fallback to visible checked checkboxes
      count = this.inputTargets.filter((input) => input.checked).length;
    }

    const label = `${count} dossier${count > 1 ? 's' : ''} sélectionné${count > 1 ? 's' : ''}`;
    this.checkboxCountTarget.textContent = label;

    const classList = this.checkboxCountTarget.classList;
    if (count > 0) {
      classList.add('text-high-blue', 'font-weight-bold');
    } else {
      classList.remove('text-high-blue', 'font-weight-bold');
    }
  }

  injectSelectedIdsIntoModal(event: Event) {
    event.preventDefault();

    if (!this.hasModalFormTarget) return;
    const modalForm = this.modalFormTarget;

    // Supprimer les inputs précédemment injectés
    modalForm
      .querySelectorAll('input[name="batch_operation[dossier_ids][]"]')
      .forEach((el) => el.remove());

    const hiddenInput = document.querySelector<HTMLInputElement>(
      '#input_multiple_ids_batch_operation'
    );
    let ids: string[] = [];

    if (hiddenInput && hiddenInput.value.trim() !== '') {
      // Cas 1 : sélection étendue (select all + select more)
      ids = hiddenInput.value
        .split(',')
        .map((id) => id.trim())
        .filter(Boolean);
    } else {
      // Cas 2 : sélection visible via les checkboxes
      const checkedInputs = document.querySelectorAll<HTMLInputElement>(
        'input[name="batch_operation[dossier_ids][]"]:checked:not(:disabled)'
      );
      ids = Array.from(checkedInputs).map((input) => input.value);
    }

    // Injecter les ids en champs cachés dans le formulaire
    ids.forEach((id) => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = 'batch_operation[dossier_ids][]';
      input.value = id;
      modalForm.appendChild(input);
    });

    // Optionnel : cocher confidentiel par défaut
    const confidentialRadio =
      document.querySelector<HTMLInputElement>('#confidentiel_true');
    if (confidentialRadio) {
      confidentialRadio.checked = true;
    }
  }
}

function isInputForOperation(operation: string) {
  return (input: HTMLInputElement) =>
    (input.dataset.operations?.split(',') ?? []).includes(operation);
}

function switchButton(button: HTMLButtonElement, flag: boolean) {
  if (flag) {
    enable(button);
    button.querySelectorAll('button').forEach((button) => enable(button));
  } else {
    disable(button);
    button.querySelectorAll('button').forEach((button) => disable(button));
  }
}

function displayNotice(inputs: HTMLInputElement[]) {
  const checkbox_all = document.querySelector<HTMLInputElement>(
    '#checkbox_all_batch_operation'
  );
  if (checkbox_all) {
    if (checkbox_all.checked) {
      show(document.querySelector('#js_batch_select_more'));
      hide(document.querySelector('#selected'));
      show(document.querySelector('#not_selected'));
    } else {
      hide(document.querySelector('#js_batch_select_more'));
      deleteSelection();
    }
  }

  const dynamic_number = document.querySelector('#dynamic_number');

  if (dynamic_number) {
    dynamic_number.textContent = inputs.length.toString();
  }
}

function deleteSelection() {
  const hidden_input_multiple_ids = document.querySelector<HTMLInputElement>(
    '#input_multiple_ids_batch_operation'
  );

  if (hidden_input_multiple_ids) {
    hidden_input_multiple_ids.value = '';
  }

  hide(document.querySelector('#js_batch_select_more'));
}

function emptyCheckboxes() {
  const inputs = document.querySelectorAll<HTMLInputElement>(
    'div[data-controller="batch-operation"] input[type=checkbox]'
  );
  inputs.forEach((e) => (e.checked = false));
}
