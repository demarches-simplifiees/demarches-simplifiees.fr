import { Application } from '@hotwired/stimulus';

import { AutosaveController } from './autosave_controller';
import { AutosaveStatusController } from './autosave_status_controller';
import { GeoAreaController } from './geo_area_controller';
import { MenuButtonController } from './menu_button_controller';
import { PersistedFormController } from './persisted_form_controller';
import { ReactController } from './react_controller';
import { ScrollToController } from './scroll_to_controller';
import { TurboEventController } from './turbo_event_controller';
import { TurboInputController } from './turbo_input_controller';
import { TurboPollController } from './turbo_poll_controller';

const Stimulus = Application.start();
Stimulus.register('autosave-status', AutosaveStatusController);
Stimulus.register('autosave', AutosaveController);
Stimulus.register('geo-area', GeoAreaController);
Stimulus.register('menu-button', MenuButtonController);
Stimulus.register('persisted-form', PersistedFormController);
Stimulus.register('react', ReactController);
Stimulus.register('scroll-to', ScrollToController);
Stimulus.register('turbo-event', TurboEventController);
Stimulus.register('turbo-input', TurboInputController);
Stimulus.register('turbo-poll', TurboPollController);
