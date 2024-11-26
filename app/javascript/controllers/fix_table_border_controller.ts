import { ApplicationController } from './application_controller';

export class FixTableBorderController extends ApplicationController {
  connect() {
    let pixelSize = Math.round((1 / window.devicePixelRatio) * 100) / 100;
    pixelSize = pixelSize < 1 ? 1 : pixelSize;
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
