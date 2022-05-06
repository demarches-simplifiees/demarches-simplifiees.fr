import { Application } from '@hotwired/stimulus';

import { ReactController } from './react_controller';
import { TurboEventController } from './turbo_event_controller';
import { GeoAreaController } from './geo_area_controller';
import { TurboInputController } from './turbo_input_controller';
import { AutosaveController } from './autosave_controller';

const Stimulus = Application.start();
Stimulus.register('react', ReactController);
Stimulus.register('turbo-event', TurboEventController);
Stimulus.register('geo-area', GeoAreaController);
Stimulus.register('turbo-input', TurboInputController);
Stimulus.register('autosave', AutosaveController);
