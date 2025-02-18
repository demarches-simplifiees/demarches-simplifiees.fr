import lightGallery from 'lightgallery';
import 'lightgallery/css/lightgallery-bundle.css';
import type { LightGallery } from 'lightgallery/lightgallery';
import lgHash from 'lightgallery/plugins/hash';
import lgRotate from 'lightgallery/plugins/rotate';
import lgThumbnail from 'lightgallery/plugins/thumbnail';
import lgZoom from 'lightgallery/plugins/zoom';
import { ApplicationController } from '../application_controller';

export default class extends ApplicationController {
  lightGallery?: LightGallery;

  connect(): void {
    const options = {
      plugins: [lgZoom, lgThumbnail, lgRotate, lgHash],
      flipVertical: false,
      flipHorizontal: false,
      animateThumb: false,
      zoomFromOrigin: false,
      allowMediaOverlap: true,
      toggleThumb: true,
      selector: '.gallery-link',
      // license key is not mandatory for open source projects but we purchased
      // an organization license to show our support (see https://www.lightgalleryjs.com/license/)
      licenseKey: import.meta.env.VITE_LIGHTGALLERY_LICENSE_KEY
    };

    const gallery = document.querySelector('.gallery');

    if (gallery != null) {
      gallery.addEventListener('lgBeforeOpen', () => {
        window.history.pushState({}, 'Gallery opened');
      });
    }

    this.lightGallery = lightGallery(this.element as HTMLElement, options);

    const downloadIcon = document.querySelector('.lg-download');

    if (downloadIcon != null) {
      downloadIcon.removeAttribute('target');
    }
  }

  disconnect(): void {
    this.lightGallery?.destroy();
  }
}
