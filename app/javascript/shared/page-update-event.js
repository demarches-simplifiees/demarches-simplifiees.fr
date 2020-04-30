import { fire } from '@utils';

addEventListener('turbolinks:load', function () {
  fire(document, 'ds:page:update');
});

addEventListener('ajax:success', function () {
  fire(document, 'ds:page:update');
});
