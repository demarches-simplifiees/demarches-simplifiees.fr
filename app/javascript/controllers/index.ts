import { Application } from '@hotwired/stimulus';

import { ReactController } from './react_controller';
import { TurboEventController } from './turbo_event_controller';
import { GeoAreaController } from './geo_area_controller';
import { TurboInputController } from './turbo_input_controller';
import { AutosaveController } from './autosave_controller';
import { AutosaveStatusController } from './autosave_status_controller';
import { MenuButtonController } from './menu_button_controller';

const Stimulus = Application.start();
Stimulus.register('react', ReactController);
Stimulus.register('turbo-event', TurboEventController);
Stimulus.register('geo-area', GeoAreaController);
Stimulus.register('turbo-input', TurboInputController);
Stimulus.register('autosave', AutosaveController);
Stimulus.register('autosave-status', AutosaveStatusController);
Stimulus.register('menu-button', MenuButtonController);
