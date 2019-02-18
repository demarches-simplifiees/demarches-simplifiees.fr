import ProgressBar from './progress-bar';

const INITIALIZE_EVENT = 'direct-upload:initialize';
const START_EVENT = 'direct-upload:start';
const PROGRESS_EVENT = 'direct-upload:progress';
const ERROR_EVENT = 'direct-upload:error';
const END_EVENT = 'direct-upload:end';

addEventListener(INITIALIZE_EVENT, ({ target, detail: { id, file } }) => {
  ProgressBar.init(target, id, file);
});

addEventListener(START_EVENT, ({ detail: { id } }) => {
  ProgressBar.start(id);
});

addEventListener(PROGRESS_EVENT, ({ detail: { id, progress } }) => {
  ProgressBar.progress(id, progress);
});

addEventListener(ERROR_EVENT, ({ detail: { id, error } }) => {
  ProgressBar.error(id, error);
});

addEventListener(END_EVENT, ({ detail: { id } }) => {
  ProgressBar.end(id);
});
