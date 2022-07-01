import { Controller } from '@hotwired/stimulus';

export class TrixController extends Controller {
  connect() {
    import('trix');
    import('@rails/actiontext');
  }
}
