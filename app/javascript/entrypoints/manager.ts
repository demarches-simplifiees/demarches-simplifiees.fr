import * as Turbo from '@hotwired/turbo';
import { Application } from '@hotwired/stimulus';

import '../shared/turbo-actions';
import '../manager/fields/features';
import { registerControllers } from '../shared/stimulus-loader';

const application = Application.start();
registerControllers(application);

Turbo.session.drive = false;
