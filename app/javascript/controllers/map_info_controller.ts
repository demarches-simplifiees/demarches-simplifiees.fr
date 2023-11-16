import { Controller } from '@hotwired/stimulus';
import { hide, show } from '@utils';

export class MapInfoController extends Controller {
  static targets = ['infos', 'departement', 'demarches', 'dossiers'];

  declare readonly infosTarget: HTMLDivElement;
  declare readonly departementTarget: HTMLDivElement;
  declare readonly demarchesTarget: HTMLDivElement;
  declare readonly dossiersTarget: HTMLDivElement;

  showInfo(event: Event) {
    const target = event.target as HTMLElement;
    if (target && target.dataset && target.dataset.departement) {
      target.setAttribute('stroke-width', '2.5');
      this.departementTarget.innerHTML = target.dataset.departement;
      this.demarchesTarget.innerHTML = Number(
        target.dataset.demarches
      ).toLocaleString();
      this.dossiersTarget.innerHTML = Number(
        target.dataset.dossiers
      ).toLocaleString();
    }
    show(this.infosTarget);
  }

  hideInfo(event: Event) {
    hide(this.infosTarget);
    const target = event.target as HTMLElement;
    target.removeAttribute('stroke-width');
  }
}
