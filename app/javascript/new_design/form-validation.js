import { delegate } from '@utils';

delegate('blur keydown', 'input, textarea', ({ target }) => {
  touch(target);
});

delegate(
  'click',
  'input[type="submit"]:not([formnovalidate])',
  ({ target }) => {
    let form = target.closest('form');
    let inputs = form ? form.querySelectorAll('input, textarea') : [];
    [...inputs].forEach(touch);
  }
);

function touch({ classList }) {
  classList.add('touched');
}
