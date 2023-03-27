import { show, hide } from '@utils';

export function showMotivation(event, state) {
  event.preventDefault();
  motivationCancel();
  const stateElement = document.querySelector(`.motivation.${state}`);

  show(stateElement.parentElement);
  show(stateElement);
  hide(document.querySelector('.dropdown-items'));
}

export function motivationCancel() {
  document.querySelectorAll('.motivation').forEach(hide);
  document
    .querySelectorAll('.motivation')
    .forEach((el) => hide(el.parentElement));

  show(document.querySelector('.dropdown-items'));
}

export function showDeleteJustificatif(name) {
  const justificatif = document.querySelector('#dossier_justificatif_motivation_' + name)
  if (justificatif.value != '') {
    show(document.querySelector('#delete_motivation_import_' + name));
  }
}

export function deleteJustificatif(name) {
  const justificatif = document.querySelector('#dossier_justificatif_motivation_' + name)
  justificatif.value = ''
  hide(document.querySelector('#delete_motivation_import_' + name));
}

export function showImportJustificatif(name) {
  show(document.querySelector('#justificatif_motivation_import_' + name));
  hide(document.querySelector('#justificatif_motivation_suggest_' + name));
}
