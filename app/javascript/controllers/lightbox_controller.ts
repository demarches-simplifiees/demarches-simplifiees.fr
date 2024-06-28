import { Controller } from '@hotwired/stimulus';
import lightGallery from 'lightgallery';
import { LightGallery } from 'lightgallery/lightgallery';
import lgThumbnail from 'lightgallery/plugins/thumbnail';
import lgZoom from 'lightgallery/plugins/zoom';
import lgRotate from 'lightgallery/plugins/rotate';
import lgHash from 'lightgallery/plugins/hash';
import 'lightgallery/css/lightgallery-bundle.css';

export default class extends Controller {
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
      selector: '.gallery-link'
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
