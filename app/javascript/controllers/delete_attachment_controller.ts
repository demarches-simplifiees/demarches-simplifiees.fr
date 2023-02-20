import { httpRequest } from '@utils';
import { ApplicationController } from './application_controller';

// When dealing with dossiers.attachements.
// their is the main form to submit each champs
// plus their is another form (not nested in the main form) to submit a delete request
// this controller connect each <button> submitting an attachment destroy request
// to the form that submit the request
export class DeleteAttachmentController extends ApplicationController {
  static targets = ['form'];

  declare readonly formTarget: HTMLFormElement;

  onSubmit(event: SubmitEvent) {
    const submitter = event.submitter;
    const action = submitter ? submitter.getAttribute('value') : null;

    event.preventDefault();
    if (submitter && action) {
      httpRequest(action, {
        method: 'post',
        body: new FormData(this.formTarget)
      }).turbo();
    }
    return false;
  }
}
