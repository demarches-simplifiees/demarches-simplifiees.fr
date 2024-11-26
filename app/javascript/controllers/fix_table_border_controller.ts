import { ApplicationController } from './application_controller';

export class FixTableBorderController extends ApplicationController {
  connect() {
    const pixelSize = Math.round((1 / window.devicePixelRatio) * 100) / 100;

    // Safari does not support devicePixelRatio
    if (navigator.userAgent.indexOf('Safari') > -1) {
      return;
    }

    const fix = document.createElement('style');
    fix.innerText = `
      .fr-table.fr-table--bordered .fr-table__content th,
      .fr-table.fr-table--bordered .fr-table__content td {
        background-size: 100% ${pixelSize}px, ${pixelSize}px 100%}
    }`;
    document.body.appendChild(fix);
  }
}
